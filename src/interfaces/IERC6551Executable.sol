// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev the ERC-165 identifier for this interface is `0x9e5d4c49`
interface IERC6551Executable {
    /**
     * @dev Executes a low-level call
     *
     * Reverts and bubbles up error if call fails
     *
     * @return The result of the call
     */
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}
