// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface IERC6551Account {
    receive() external payable;

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        );

    function owner() external view returns (address);
}
