// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./lib/ERC6551BytecodeLib.sol";

contract ERC6551Registry is IERC6551Registry {
    error InitializationFailed();

    /// @dev Function to create the ERC721 Smart Account.
    /// @param implementation ERC721 Smart Account Contract Address
    /// @param chainId Chain ID of the blockchain
    /// @param tokenContract ERC721 contract address
    /// @param tokenId Token ID of the ERC721
    /// @param salt Some Randomness
    /// @param initData Data to be executed on the ERC721 Smart Account
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        // Getting the smart contract account byte
        bytes memory code = ERC6551BytecodeLib.getCreationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        // Compute the address of the smart contract account
        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        // If address returned is not equal to 0, it returns the address else deploy the smart contract account
        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, chainId, tokenContract, tokenId, salt);

        _account = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        return _account;
    }

    /// @dev Function to get the ERC721 Smart Account Address.
    /// @param implementation ERC721 Smart Account Contract Address
    /// @param chainId Chain ID of the blockchain
    /// @param tokenContract ERC721 contract address
    /// @param tokenId Token ID of the ERC721
    /// @param salt Some Randomness
    /// @return address of the ERC721 Smart Account
    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            ERC6551BytecodeLib.getCreationCode(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            )
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
