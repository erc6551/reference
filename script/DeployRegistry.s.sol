// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "../src/ERC6551Registry.sol";

contract DeployRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new ERC6551Registry{
            salt: 0x6551655165516551655165516551655165516551655165516551655165516551
        }();

        vm.stopBroadcast();
    }
}
