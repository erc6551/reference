// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "../src/ERC6551Registry.sol";

contract ComputeRegistryAddress is Script {
    function run() external view {
        bytes32 salt = 0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31;
        address factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

        address registry =
            Create2.computeAddress(salt, keccak256(type(ERC6551Registry).creationCode), factory);

        console.log("ERC6551Registry Address:", registry);
    }
}
