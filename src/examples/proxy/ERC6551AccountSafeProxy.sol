// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author: manifold.xyz

import "openzeppelin-contracts/interfaces/IERC1271.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import "openzeppelin-contracts/utils/StorageSlot.sol";
import "openzeppelin-contracts/proxy/Proxy.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";

import "../../lib/ERC6551AccountByteCode.sol";
import "../../interfaces/IERC6551Account.sol";

/**
 * ERC6551Account implementation that is an upgradeable proxy
 *
 * This example is a less generic implementation that enforces
 * certain security properties by
 *  - requiring that the token holder is the one who initializes the account
 *  - defining the core IERC6551Account function operations in the proxy itself. 
 *  - defining the upgrade function in the proxy itself and only permitting the
 *    token holder to upgrade the implementation.
 *
 * Rationale:
 *  - By requiring that the token holder is the one who initializes the account,
 *    we prevent a malicious actor from front-running an account with an insecure
 *    implementation.
 *  - By defining all the IERC6551Account functions in the proxy, we can ensure
 *    that a malicious implementation cannot:
 *      - spoof the token the account is associated with
 *      - spoof the nonce
 *      - spoof the owner
 *      - spoof the executeCall function and prevent nonce increment
 *  - Note that even with these security properties, the implementation can
 *    modify the nonce via a method not defined by the proxy.
 */
contract ERC6551AccountSafeProxy is Initializable, Proxy, IERC6551Account, IERC1271 {

    uint256 private _nonce;

    constructor() {
        assert(
            _IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
    }

    /**
     * Initializer
     */
    function initialize(address implementation_) public initializer {
        (uint256 chainId, address contractAddress, uint256 tokenId) = ERC6551AccountByteCode
            .token();

        /**
         * @dev We require that only the token owner can initialize the proxy, otherwise
         *      the proxy is subject to a front-running attack.
         */
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

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Upgrades the implementation.  Only the token owner can call this.
     */
    function upgrade(address implementation_) public {
        require(owner() == msg.sender, "Caller is not owner");
        require(implementation_ != address(0), "Invalid implementation address");
        ++_nonce;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    /**
     * @dev {See IERC6551Account-token}
     */
    function token() external view override returns (uint256, address, uint256) {
        return ERC6551AccountByteCode.token();
    }

    /**
     * @dev {See IERC6551Account-owner}
     */
    function owner() public view override returns (address) {
        (uint256 chainId, address contractAddress, uint256 tokenId) = ERC6551AccountByteCode
            .token();
        if (chainId != block.chainid) return address(0);
        return IERC721(contractAddress).ownerOf(tokenId);
    }

    /**
     * @dev {See IERC6551Account-nonce}
     */
    function nonce() external view override returns (uint256) {
        return _nonce;
    }

    /**
     * @dev {See IERC6551Account-owner}
     */
    function executeCall(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external payable override returns (bytes memory _result) {
        require(owner() == msg.sender, "Caller is not owner");
        ++_nonce;
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, _result) = _target.call{value: _value}(_data);
        require(success, string(_result));
        emit TransactionExecuted(_target, _value, _data);
        return _result;
    }

    receive() external payable override(Proxy, IERC6551Account) {
        _fallback();
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}
