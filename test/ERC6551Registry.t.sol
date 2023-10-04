// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

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

        console.log("Account Interface");
        console.logBytes4(type(IERC6551Account).interfaceId);
        console.log("Execution Interface");
        console.logBytes4(type(IERC6551Executable).interfaceId);
        console.log("execute selector");
        console.logBytes4(IERC6551Executable.execute.selector);
        console.log("isValidSigner");
        console.logBytes4(IERC6551Account.isValidSigner.selector);
    }

    function testDeploy() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        bytes32 salt = bytes32(uint256(400));

         address deployedAccount = registry.createAccount(
            address(implementation),
            salt,
            chainId,
            tokenAddress,
            tokenId
        );

        address registryComputedAddress =
            registry.account(address(implementation), salt, chainId, tokenAddress, tokenId);

        assertEq(deployedAccount, registryComputedAddress);
    }
}
