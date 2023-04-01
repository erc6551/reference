// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";

contract ERC6551Registry is IERC6551Registry {
    error InvalidImplementation();
    error InitializationFailed();

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed,
        bytes calldata initData
    ) external returns (address) {
        bytes32 salt = keccak256(
            abi.encode(chainId, tokenContract, tokenId, seed)
        );
        bytes memory code = _creationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId
        );

        address _account = Create2.deploy(0, salt, code);

        bool isValidImplementation = ERC165Checker.supportsInterface(
            _account,
            type(IERC6551Account).interfaceId
        );

        if (!isValidImplementation) revert InvalidImplementation();

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        emit AccountCreated(
            _account,
            implementation,
            chainId,
            tokenContract,
            tokenId,
            seed
        );

        return _account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed
    ) external view returns (address) {
        bytes32 salt = keccak256(
            abi.encode(chainId, tokenContract, tokenId, seed)
        );
        bytes32 bytecodeHash = keccak256(
            _creationCode(implementation, chainId, tokenContract, tokenId)
        );

        return Create2.computeAddress(salt, bytecodeHash);
    }

    function _creationCode(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d608e80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf300",
                abi.encode(chainId, tokenContract, tokenId)
            );
    }
}
