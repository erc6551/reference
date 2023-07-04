// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../../src/ERC6551Registry.sol";
import "../../../src/examples/initializable/InitializableERC6551Account.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC6551Account.sol";

contract InitializableERC6551AccountTest is Test {
    ERC6551Registry public registry;
    InitializableERC6551Account public implementation;
    MockERC721 nft = new MockERC721();

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new InitializableERC6551Account(address(registry));
    }

    function testAuthenticatedDeploy() public {
        nft.mint(vm.addr(1), 1);

        // initialization reverts if not called by token holder
        vm.expectRevert("Only initializable by token holder");
        registry.createAccount(
            address(implementation),
            block.chainid,
            address(nft),
            1,
            0,
            abi.encodeWithSignature("initialize()")
        );

        vm.prank(vm.addr(1));
        address deployedAccount = registry.createAccount(
            address(implementation),
            block.chainid,
            address(nft),
            1,
            0,
            abi.encodeWithSignature("initialize()")
        );

        assertTrue(deployedAccount != address(0));

        address predictedAccount = registry.account(
            address(implementation),
            block.chainid,
            address(nft),
            1,
            0
        );

        assertEq(predictedAccount, deployedAccount);

        assertEq(InitializableERC6551Account(payable(deployedAccount)).creator(), vm.addr(1));
    }
}
