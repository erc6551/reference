// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../src/ERC6551Registry.sol";
import "../../../src/examples/simple/SimpleERC6551Account.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC6551Account.sol";

contract AccountTest is Test {
    ERC6551Registry public registry;
    SimpleERC6551Account public implementation;
    MockERC721 nft = new MockERC721();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new SimpleERC6551Account();
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
}
