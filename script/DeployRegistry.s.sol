// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "../src/ERC6551Registry.sol";

contract DeployRegistry is Script {
    function run() external {
        vm.startBroadcast();

        new ERC6551Registry{
            salt: 0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31
        }();

        vm.stopBroadcast();
    }
}
