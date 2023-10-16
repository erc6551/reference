// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ERC6551Registry as EIPInlinedRegistry} from "../src/eip/ERC6551Registry.sol";
import "../src/ERC6551Registry.sol";
import "../src/lib/ERC6551AccountLib.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC6551Account.sol";

import "../src/interfaces/IERC6551Executable.sol";

contract RegistryTest is Test {
    ERC6551Registry public registry;
    MockERC6551Account public implementation;

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new MockERC6551Account();

        // Ensure interface IDs don't unexpectedly change
        assertEq(type(IERC6551Account).interfaceId, bytes4(0x6faff5f1));
        assertEq(type(IERC6551Executable).interfaceId, bytes4(0x51945447));

        console.log("Account Interface");
        console.logBytes4(type(IERC6551Account).interfaceId);
        console.log("Execution Interface");
        console.logBytes4(type(IERC6551Executable).interfaceId);
        console.log("isValidSigner");
        console.logBytes4(IERC6551Account.isValidSigner.selector);
    }

    function testDeploy() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        bytes32 salt = bytes32(uint256(400));

        address deployedAccount =
            registry.createAccount(address(implementation), salt, chainId, tokenAddress, tokenId);

        address registryComputedAddress =
            registry.account(address(implementation), salt, chainId, tokenAddress, tokenId);

        assertEq(deployedAccount, registryComputedAddress);
    }

    function testCompiledAddressEqualsInlinedAddress() public {
        bytes32 salt = 0x6551655165516551655165516551655165516551655165516551655165516551;
        address factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

        address eipRegistry =
            Create2.computeAddress(salt, keccak256(type(EIPInlinedRegistry).creationCode), factory);
        address sourceRegistry =
            Create2.computeAddress(salt, keccak256(type(ERC6551Registry).creationCode), factory);

        assertEq(eipRegistry, sourceRegistry);
    }
}
