// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../src/ERC6551Registry.sol";
import "../../../src/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import "../../../src/examples/upgradeable/ERC6551AccountProxy.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC1155.sol";
import "../../mocks/MockERC6551Account.sol";

contract AccountProxyTest is Test {
    ERC6551Registry public registry;
    ERC6551AccountUpgradeable public implementation;
    ERC6551AccountProxy public proxy;
    MockERC721 nft = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new ERC6551AccountUpgradeable();
        proxy = new ERC6551AccountProxy(address(implementation));
    }

    function testDeploy() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        address predictedAccount =
            registry.account(address(proxy), salt, block.chainid, address(nft), tokenId);

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);

        address deployedAccount =
            registry.createAccount(address(proxy), salt, block.chainid, address(nft), tokenId);

        assertTrue(deployedAccount != address(0));

        assertEq(predictedAccount, deployedAccount);

        // Create account is idempotent
        deployedAccount =
            registry.createAccount(address(proxy), salt, block.chainid, address(nft), tokenId);
        assertEq(predictedAccount, deployedAccount);
    }

    function testTokenAndOwnership() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account =
            registry.createAccount(address(proxy), salt, block.chainid, address(nft), tokenId);

        IERC6551Account accountInstance = IERC6551Account(payable(account));

        // Check token and owner functions
        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, block.chainid);
        assertEq(tokenAddress_, address(nft));
        assertEq(tokenId_, tokenId);
        assertEq(accountInstance.isValidSigner(owner, ""), IERC6551Account.isValidSigner.selector);

        // Transfer token to new owner and make sure account owner changes
        address newOwner = vm.addr(2);
        vm.prank(owner);
        nft.safeTransferFrom(owner, newOwner, tokenId);
        assertEq(
            accountInstance.isValidSigner(newOwner, ""), IERC6551Account.isValidSigner.selector
        );
    }

    function testPermissionControl() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(implementation), salt, block.chainid, address(nft), tokenId
        );

        vm.deal(account, 1 ether);

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(account);

        vm.prank(vm.addr(3));
        vm.expectRevert("Caller is not owner");
        executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

        vm.prank(owner);
        executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.state(), 1);
    }

    function testCannotOwnSelf() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(implementation), salt, block.chainid, address(nft), tokenId
        );

        vm.prank(owner);
        vm.expectRevert("Cannot own yourself");
        nft.safeTransferFrom(owner, account, tokenId);
    }

    function testCannotHaveCircularOwnershipChain() public {
        address owner1 = vm.addr(1);
        address owner2 = vm.addr(2);
        address owner3 = vm.addr(3);

        MockERC721 nft1 = new MockERC721();
        MockERC721 nft2 = new MockERC721();
        MockERC721 nft3 = new MockERC721();

        uint256 tokenId1 = 100;
        uint256 tokenId2 = 100;
        uint256 tokenId3 = 100;

        nft1.mint(owner1, tokenId1);
        nft2.mint(owner2, tokenId2);
        nft3.mint(owner3, tokenId3);

        vm.prank(owner1, owner1);
        address account1 = registry.createAccount(
            address(implementation), 0, block.chainid, address(nft1), tokenId1
        );
        vm.prank(owner2, owner2);
        address account2 = registry.createAccount(
            address(implementation), 0, block.chainid, address(nft2), tokenId2
        );
        vm.prank(owner3, owner3);
        address account3 = registry.createAccount(
            address(implementation), 0, block.chainid, address(nft3), tokenId3
        );

        // Move token that holds nft1 token1 to the wallet of nft2 token2 (this is ok)
        vm.prank(owner1);
        nft1.safeTransferFrom(owner1, account2, tokenId1);

        // Ensure you can't loop wallet ownership by sending nft2 token2 to the wallet of nft1 token1,
        // because the wallet of nft2 token2 owns nft1 token1 and doing so would create a circular loop
        vm.prank(owner2);
        vm.expectRevert("Token in ownership chain");
        nft2.safeTransferFrom(owner2, account1, tokenId2);

        // Attempt to create a 3 token loop
        vm.prank(owner2);
        nft2.safeTransferFrom(owner2, account3, tokenId2);

        // Now: nft2-2's wallet owns nft1-1 token.  nft3-3's wallet owns nft2-2 token.
        // Try to make nft1-1's wallet own nft3-3's token
        vm.prank(owner3);
        vm.expectRevert("Token in ownership chain");
        nft3.safeTransferFrom(owner3, account1, tokenId3);
    }

    function testDepthTooDeep() public {
        address owner1 = vm.addr(1);
        address owner2 = vm.addr(2);
        address owner3 = vm.addr(3);
        address owner4 = vm.addr(4);
        address owner5 = vm.addr(5);
        address owner6 = vm.addr(6);
        address owner7 = vm.addr(7);

        nft.mint(owner1, 100);
        nft.mint(owner2, 200);
        nft.mint(owner3, 300);
        nft.mint(owner4, 400);
        nft.mint(owner5, 500);
        nft.mint(owner6, 600);
        nft.mint(owner7, 700);

        vm.prank(owner1, owner1);
        address account1 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 100
        );
        vm.prank(owner2, owner2);
        address account2 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 200
        );
        vm.prank(owner3, owner3);
        address account3 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 300
        );
        vm.prank(owner4, owner4);
        address account4 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 400
        );
        vm.prank(owner5, owner5);
        address account5 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 500
        );
        vm.prank(owner6, owner6);
        address account6 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 600
        );
        vm.prank(owner7, owner7);
        address account7 = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), 700
        );

        vm.prank(owner1);
        nft.safeTransferFrom(owner1, account2, 100);
        vm.prank(owner2);
        nft.safeTransferFrom(owner2, account3, 200);
        vm.prank(owner3);
        nft.safeTransferFrom(owner3, account4, 300);
        vm.prank(owner4);
        nft.safeTransferFrom(owner4, account5, 400);
        vm.prank(owner5);
        nft.safeTransferFrom(owner5, account6, 500);
        vm.prank(owner6);
        nft.safeTransferFrom(owner6, account7, 600);
        vm.prank(owner7);
        vm.expectRevert("Ownership chain too deep");
        nft.safeTransferFrom(owner7, account1, 700);
    }

    function testUpgrade() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account =
            registry.createAccount(address(proxy), salt, block.chainid, address(nft), tokenId);

        MockERC6551Account implementation2 = new MockERC6551Account();

        vm.prank(vm.addr(2));
        vm.expectRevert("Caller is not owner");
        ERC6551AccountUpgradeable(payable(account)).upgrade(address(implementation2));

        vm.prank(owner);
        ERC6551AccountUpgradeable(payable(account)).upgrade(address(implementation2));

        bytes32 rawImplementation =
            vm.load(account, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

        assertEq(address(uint160(uint256(rawImplementation))), address(implementation2));

        vm.prank(owner);
        vm.expectRevert("disabled");
        IERC6551Executable(account).execute(owner, 0, "", 0);
    }

    function testProxyInitializeERC1967ImplementationSlot() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;
        bytes32 salt = bytes32(uint256(200));

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account =
            registry.createAccount(address(proxy), salt, block.chainid, address(nft), tokenId);

        // Check that even if the implementation is not in storage, the proxy still can function.
        assertEq(ERC6551AccountUpgradeable(payable(account)).owner(), owner);

        bytes32 rawImplementation =
            vm.load(account, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

        assertEq(address(uint160(uint256(rawImplementation))), address(0));

        // Send ETH to initialize.
        (bool success, ) = payable(account).call{value: 0}("");
        assertTrue(success);

        rawImplementation =
            vm.load(account, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

        assertEq(address(uint160(uint256(rawImplementation))), address(implementation));
        
    }

    function testERC721Receive() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), tokenId
        );

        address otherOwner = vm.addr(2);
        uint256 otherTokenId = 200;
        nft.mint(otherOwner, otherTokenId);
        vm.prank(otherOwner);
        nft.safeTransferFrom(otherOwner, account, otherTokenId);
        assertEq(nft.balanceOf(account), 1);
        assertEq(nft.ownerOf(otherTokenId), account);
    }

    function testERC1155Receive() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(implementation), bytes32(0), block.chainid, address(nft), tokenId
        );

        uint256 tokenId1155 = 200;
        uint256 amount1155 = 10;
        address otherOwner = vm.addr(2);

        nft1155.mint(otherOwner, tokenId1155, amount1155);

        vm.prank(otherOwner);
        nft1155.safeTransferFrom(otherOwner, account, tokenId1155, 2, "");
        assertEq(nft1155.balanceOf(account, tokenId1155), 2);
        assertEq(nft1155.balanceOf(otherOwner, tokenId1155), amount1155 - 2);
    }

    function testOwnershipChain() public {
        address owner1 = vm.addr(1);
        address owner2 = vm.addr(2);
        address owner3 = vm.addr(3);
        address owner4 = vm.addr(4);
        address newTokenOwner = vm.addr(7);
        bytes32 salt = bytes32(uint256(0));

        nft.mint(owner1, 100);
        nft.mint(owner2, 200);
        nft.mint(owner3, 300);
        nft.mint(owner4, 400);

        vm.prank(owner1, owner1);
        registry.createAccount(address(implementation), salt, block.chainid, address(nft), 100);
        vm.prank(owner2, owner2);
        address account2 =
            registry.createAccount(address(implementation), salt, block.chainid, address(nft), 200);
        vm.prank(owner3, owner3);
        address account3 =
            registry.createAccount(address(implementation), salt, block.chainid, address(nft), 300);
        vm.prank(owner4, owner4);
        address account4 =
            registry.createAccount(address(implementation), salt, block.chainid, address(nft), 400);

        vm.prank(owner1);
        nft.safeTransferFrom(owner1, account2, 100);
        vm.prank(owner2);
        nft.safeTransferFrom(owner2, account3, 200);
        vm.prank(owner3);
        nft.safeTransferFrom(owner3, account4, 300);

        // Make sure that we can transfer out token 200
        vm.prank(owner4);
        IERC6551Executable(account4).execute(
            address(account3),
            0,
            abi.encodeWithSignature(
                "execute(address,uint256,bytes,uint8)",
                address(nft),
                0,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)", account3, newTokenOwner, 200
                ),
                0
            ),
            0
        );

        assertEq(nft.ownerOf(200), newTokenOwner);
    }

    function testProxyZeroAddressInit() public {
        vm.expectRevert(InvalidImplementation.selector);
        new ERC6551AccountProxy(address(0));
    }
}
