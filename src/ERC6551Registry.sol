// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./lib/ERC6551BytecodeLib.sol";

contract ERC6551Registry is IERC6551Registry {
    error AccountCreationFailed();

    /**
     * @dev {See IERC6551Registry-createAccount}
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        bytes memory code = ERC6551BytecodeLib.getCreationCode(
            implementation, salt, chainId, tokenContract, tokenId
        );

        address _account = Create2.computeAddress(salt, keccak256(code));

        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, salt, chainId, tokenContract, tokenId);

        assembly {
            _account := create2(0, add(code, 0x20), mload(code), salt)
        }

        if (_account == address(0)) revert AccountCreationFailed();

        return _account;
    }

    /**
     * @dev {See IERC6551Registry-account}
     */
    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            ERC6551BytecodeLib.getCreationCode(
                implementation, salt, chainId, tokenContract, tokenId
            )
        );

        return Create2.computeAddress(salt, bytecodeHash);
    }
}
