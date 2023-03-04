// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";

contract ERC6551Registry is IERC6551Registry {
    error InvalidImplementation();

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        bool isValidImplementation = ERC165Checker.supportsInterface(
            implementation,
            type(IERC6551Account).interfaceId
        );

        if (!isValidImplementation) revert InvalidImplementation();

        bytes32 salt = keccak256(abi.encode(chainId, tokenContract, tokenId));
        bytes memory code = _creationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId
        );

        return Create2.deploy(0, salt, code);
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(chainId, tokenContract, tokenId));
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
