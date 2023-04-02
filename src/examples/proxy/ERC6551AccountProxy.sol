// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author: manifold.xyz

import "openzeppelin-contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/interfaces/IERC1271.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/utils/StorageSlot.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

import "../../lib/ERC6551AccountByteCode.sol";

interface IERC6551AccountProxy {
    function _supportsInterface(bytes4) external view returns (bool);

    function _owner() external view returns (address);
}

/**
 * ERC6551Account implementation that is an upgradeable proxy
 */
contract ERC6551AccountProxy is Initializable, IERC1271, IERC165 {
    uint256 public nonce;

    constructor() {
        assert(
            _IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
    }

    modifier onlyOwner() {
        (bool success, bytes memory data) = _implementation().delegatecall(
            abi.encodeWithSignature("owner()")
        );
        require(success && abi.decode(data, (address)) == msg.sender, "Caller is not owner");
        _;
    }

    /**
     * Initializer
     */
    function initialize(address implementation_) public initializer {
        (uint256 chainId, address contractAddress, uint256 tokenId) = ERC6551AccountByteCode
            .token();
        require(
            chainId == block.chainid && IERC721(contractAddress).ownerOf(tokenId) == tx.origin,
            "Not owner of token"
        );
        require(implementation_ != address(0), "Invalid implementation address");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Upgrades the implementation.  Only the token owner can call this.
     */
    function upgrade(address implementation_) public onlyOwner {
        require(implementation_ != address(0), "Invalid implementation address");
        ++nonce;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        ++nonce;
        _delegate(_implementation());
    }

    /**
     * @dev Returns the owner token chainId, contract address, and token id.
     */
    function token() external view returns (uint256, address, uint256) {
        return ERC6551AccountByteCode.token();
    }

    /**
     * @dev Returns the owner of the token owned wallet
     */
    function owner() external view returns (address) {
        // We do this in order to do a view delegatecall
        return IERC6551AccountProxy(address(this))._owner();
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        // We do this in order to do a view delegatecall
        return IERC6551AccountProxy(address(this))._supportsInterface(interfaceId);
    }

    function _owner() external returns (address) {
        (bool success, bytes memory data) = _implementation().delegatecall(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Failed to get owner");
        return abi.decode(data, (address));
    }

    function _supportsInterface(bytes4 interfaceId) external returns (bool) {
        (bool success, bytes memory data) = _implementation().delegatecall(
            abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId)
        );
        require(success, "Failed to get supportsInterface");
        return abi.decode(data, (bool));
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(IERC6551AccountProxy(address(this))._owner(), hash, signature);
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}
