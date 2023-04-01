// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/ERC6551Registry.sol";
import "../src/ExampleERC6551Account.sol";
import "./mocks/MockERC721.sol";

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

        assertEq(IERC6551Account(payable(account)).owner(), vm.addr(1));

        vm.deal(account, 1 ether);

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        vm.prank(vm.addr(1));
        accountInstance.executeCall(payable(vm.addr(2)), 0.5 ether, "");

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.nonce(), 1);
    }
}
