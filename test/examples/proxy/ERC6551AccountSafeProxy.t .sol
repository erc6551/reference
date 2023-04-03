// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../../src/ERC6551Registry.sol";
import "../../../src/examples/proxy/ERC6551AccountSafeProxy.sol";
import "../../../src/examples/proxy/ERC6551AccountSafeProxyImpl.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC1155.sol";
import "./mocks/MaliciousERC6551AccountProxyImpl.sol";

contract AccountSafeProxyTest is Test {
    ERC6551Registry public registry;
    ERC6551AccountSafeProxy public proxy;
    ERC6551AccountSafeProxyImpl public proxyImpl;
    MaliciousERC6551AccountProxyImpl public maliciousProxyImpl;
    MockERC721 nft = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    function setUp() public {
        registry = new ERC6551Registry();
        proxy = new ERC6551AccountSafeProxy();
        proxyImpl = new ERC6551AccountSafeProxyImpl();
        maliciousProxyImpl = new MaliciousERC6551AccountProxyImpl();
    }

    function testDeploy() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        address predictedAccount = registry.account(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0
        );

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);

        address deployedAccount = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );

        assertTrue(deployedAccount != address(0));

        assertEq(predictedAccount, deployedAccount);

        address implementation = ERC6551AccountSafeProxy(payable(deployedAccount)).implementation();
        assertEq(implementation, address(proxyImpl));

        // Can't be deployed twice
        vm.expectRevert("Create2: Failed on deploy");
        registry.createAccount(address(proxy), block.chainid, address(nft), tokenId, 0, "");

        // Can't be initialized twice
        vm.expectRevert("Initializable: contract is already initialized");
        deployedAccount.call(abi.encodeWithSignature("initialize(address)", address(proxyImpl)));
    }

    function testTokenAndOwnership() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );

        IERC6551Account accountInstance = IERC6551Account(payable(account));

        // Check token and owner functions
        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, block.chainid);
        assertEq(tokenAddress_, address(nft));
        assertEq(tokenId_, tokenId);
        assertEq(accountInstance.owner(), owner);

        // Transfer token to new owner and make sure account owner changes
        address newOwner = vm.addr(2);
        vm.prank(owner);
        nft.safeTransferFrom(owner, newOwner, tokenId);
        assertEq(accountInstance.owner(), newOwner);
    }

    function testPermissionControl() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );

        vm.deal(account, 1 ether);
        IERC6551Account accountInstance = IERC6551Account(payable(account));
        vm.prank(vm.addr(3));
        vm.expectRevert("Caller is not owner");
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        vm.prank(owner);
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.nonce(), 1);
    }

    function testDeployNotTokenOwner() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        address otherAddress = vm.addr(2);
        vm.prank(otherAddress, otherAddress);
        vm.expectRevert(bytes4(keccak256("InitializationFailed()")));

        registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );
    }

    function testCannotOwnSelf() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
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
            address(proxy),
            block.chainid,
            address(nft1),
            tokenId1,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );
        vm.prank(owner2, owner2);
        address account2 = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft2),
            tokenId2,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );
        vm.prank(owner3, owner3);
        address account3 = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft3),
            tokenId3,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
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

    function testUpgrade() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
        );

        ERC6551AccountSafeProxyImpl proxyImpl2 = new ERC6551AccountSafeProxyImpl();
        vm.prank(vm.addr(2));
        vm.expectRevert("Caller is not owner");
        ERC6551AccountSafeProxy(payable(account)).upgrade(address(proxyImpl2));

        vm.prank(owner);
        ERC6551AccountSafeProxy(payable(account)).upgrade(address(proxyImpl2));
        assertEq(ERC6551AccountSafeProxy(payable(account)).implementation(), address(proxyImpl2));
    }

    function testERC721Receive() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
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
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(proxyImpl))
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

    function testMalciousImplementation() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(proxy),
            block.chainid,
            address(nft),
            tokenId,
            0,
            abi.encodeWithSignature("initialize(address)", address(maliciousProxyImpl))
        );

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        
        // We have a malicious implementation that overrides nonce(), token(), owner() and executeCall()
        // make sure those are ignored in favor of the safe proxy
        // Check token and owner functions
        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, block.chainid);
        assertEq(tokenAddress_, address(nft));
        assertEq(tokenId_, tokenId);
        assertEq(accountInstance.owner(), owner);

        // Check upgrade permissions
        ERC6551AccountSafeProxyImpl proxyImpl2 = new ERC6551AccountSafeProxyImpl();
        vm.prank(vm.addr(2));
        vm.expectRevert("Caller is not owner");
        ERC6551AccountSafeProxy(payable(account)).upgrade(address(proxyImpl2));

        // Check executeCall permissions
        vm.deal(account, 1 ether);
        vm.prank(vm.addr(3));
        vm.expectRevert("Caller is not owner");
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        vm.prank(owner);
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");
        assertEq(accountInstance.nonce(), 1);

        // Transfer token to new owner and make sure account owner changes
        address newOwner = vm.addr(2);
        vm.prank(owner);
        nft.safeTransferFrom(owner, newOwner, tokenId);
        assertEq(accountInstance.owner(), newOwner);

    }
}
