// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";

contract ERC6551Registry is IERC6551Registry {
    error InvalidImplementation();
    error InitializationFailed();

    bytes constant creationCode =
        hex"6044603d608081019182918101608060a0820191016000396000517f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc556000396000f3fe600036818037808036817f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d82803e156039573d90f35b3d90fd";

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = abi.encodePacked(
            creationCode,
            abi.encode(salt, chainId, tokenContract, tokenId, implementation)
        );

        address _account = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        bool isValidImplementation = ERC165Checker.supportsInterface(
            _account,
            type(IERC6551Account).interfaceId
        );

        if (!isValidImplementation) revert InvalidImplementation();

        emit AccountCreated(
            _account,
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        return _account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                creationCode,
                abi.encode(
                    salt,
                    chainId,
                    tokenContract,
                    tokenId,
                    implementation
                )
            )
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
