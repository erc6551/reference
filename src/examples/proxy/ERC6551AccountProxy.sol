// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author: manifold.xyz

import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/utils/StorageSlot.sol";
import "openzeppelin-contracts/proxy/Proxy.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";

import "../../lib/ERC6551AccountByteCode.sol";

/**
 * ERC6551Account implementation that is an upgradeable proxy
 * This defers all logic to the implementation and is only meant
 * to serve as an example of how one could deploy an ERC6551 account
 * that is an upgradeable proxy.
 *
 * Please do not use as is without understanding the security implications.
 * This implementation contains known vulnerabilities
 * such as the ability for a malicious actor to front-run the wallet of
 * a token with a malicious implementation.
 */
contract ERC6551AccountProxy is Initializable, Proxy {
    /**
     * Initializer
     */
    function initialize(address implementation_) public initializer {
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


}
