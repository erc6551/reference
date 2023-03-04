// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551Registry {
    event AccountCreated(
        address account,
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    );

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address);

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address);
}
