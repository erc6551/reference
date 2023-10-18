// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "../src/lib/ERC6551BytecodeLib.sol";

contract ERC6551AccountLibTest is Test {
    function testERC6551BytecodeLibDifferential(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public {
        bytes memory computed = ERC6551BytecodeLib.getCreationCode(
            implementation, salt, chainId, tokenContract, tokenId
        );
        bytes memory expected = abi.encodePacked(
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3",
            abi.encode(salt, chainId, tokenContract, tokenId)
        );
        assertEq(computed, expected);
    }

    function testERC6551BytecodeLibComputeAddressDifferential(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) public {
        address computed = ERC6551BytecodeLib.computeAddress(salt, bytecodeHash, deployer);
        address expected = Create2.computeAddress(salt, bytecodeHash, deployer);
        assertEq(computed, expected);
    }
}
