// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ERC6551BytecodeLib {
    /**
     * @dev Returns the creation code of the token bound account for a non-fungible token.
     *
     * @return result The creation code of the token bound account
     */
    function getCreationCode(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal pure returns (bytes memory result) {
        assembly {
            result := mload(0x40) // Grab the free memory pointer
            // Layout the variables and bytecode backwards
            mstore(add(result, 0xb7), tokenId)
            mstore(add(result, 0x97), shr(96, shl(96, tokenContract)))
            mstore(add(result, 0x77), chainId)
            mstore(add(result, 0x57), salt)
            mstore(add(result, 0x37), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x28), implementation)
            mstore(add(result, 0x14), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            mstore(result, 0xb7) // Store the length
            mstore(0x40, add(result, 0xd7)) // Allocate the memory
        }
    }

    /**
     * @dev Returns the create2 address computed from `salt`, `bytecodeHash`, `deployer`.
     *
     * @return result The create2 address computed from `salt`, `bytecodeHash`, `deployer`
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
        internal
        pure
        returns (address result)
    {
        assembly {
            result := mload(0x40) // Grab the free memory pointer
            mstore8(result, 0xff)
            mstore(add(result, 0x35), bytecodeHash)
            mstore(add(result, 0x01), shl(96, deployer))
            mstore(add(result, 0x15), salt)
            result := keccak256(result, 0x55)
        }
    }
}
