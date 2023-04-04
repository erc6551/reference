// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/ERC6551Registry.sol";
import "../src/ExampleERC6551Account.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC6551Account.sol";

contract RegistryTest is Test {
    ERC6551Registry public registry;
    MockERC6551Account public implementation;

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new MockERC6551Account();
    }

    function testDeploy() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        uint256 salt = 400;
        address deployedAccount;
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InvalidImplementation()"))));
        deployedAccount = registry.createAccount(
            address(implementation),
            chainId,
            tokenAddress,
            tokenId,
            salt,
            ""
        );

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InitializationFailed()"))));
        deployedAccount = registry.createAccount(
            address(implementation),
            chainId,
            tokenAddress,
            tokenId,
            salt,
            abi.encodeWithSignature("initialize(bool)", false)
        );

        deployedAccount = registry.createAccount(
            address(implementation),
            chainId,
            tokenAddress,
            tokenId,
            salt,
            abi.encodeWithSignature("initialize(bool)", true)
        );

        MockERC6551Account accountInstance = MockERC6551Account(payable(deployedAccount));

        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, chainId);
        assertEq(tokenAddress_, tokenAddress);
        assertEq(tokenId_, tokenId);

        assertEq(salt, accountInstance.salt());

        console.log(accountInstance.codeLength());
    }
}

contract AccountTest is Test {
    ERC6551Registry public registry;
    ExampleERC6551Account public implementation;
    MockERC721 nft = new MockERC721();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new ExampleERC6551Account();
    }

    function testDeploy() public {
        address deployedAccount = registry.createAccount(
            address(implementation),
            block.chainid,
            address(0),
            0,
            0,
            ""
        );

        assertTrue(deployedAccount != address(0));

        address predictedAccount = registry.account(
            address(implementation),
            block.chainid,
            address(0),
            0,
            0
        );

        assertEq(predictedAccount, deployedAccount);

        console.logBytes4(type(IERC6551Account).interfaceId);
    }

    function testCall() public {
        nft.mint(vm.addr(1), 1);

        address account = registry.createAccount(
            address(implementation),
            block.chainid,
            address(nft),
            1,
            0,
            ""
        );

        assertTrue(account != address(0));

        IERC6551Account accountInstance = IERC6551Account(payable(account));

        assertEq(accountInstance.owner(), vm.addr(1));

        vm.deal(account, 1 ether);

        vm.prank(vm.addr(1));
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.nonce(), 1);
    }

    function testImplementationQuery() public {
        nft.mint(vm.addr(1), 1);

        address account = registry.createAccount(
            address(implementation),
            block.chainid,
            address(nft),
            1,
            0,
            ""
        );

        assertTrue(account != address(0));

        IERC6551Account accountInstance = IERC6551Account(payable(account));

        assertEq(accountInstance.owner(), vm.addr(1));

        address accountImplementation = IERC6551AccountProxy(account).implementation();

        assertEq(accountImplementation, address(implementation));
    }
}
