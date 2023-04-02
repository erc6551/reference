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
 */
contract ERC6551AccountProxy is Initializable, Proxy {
    /**
     * @dev nonce is defined at the proxy level because it needs to be incremented
     *      when the implementation is upgraded.
     * note: nonce should also be incremented by the implementation whenever executeCall
     *       is called, or whenever state is changed.  A bad implementation could
     *       manipulate the nonce in malicious ways though, so it is up to a proxy
     *       implementer to provide additional checks as necessary.
     */
    uint256 public nonce;

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
        (bool success, bytes memory data) = _implementation().delegatecall(
            abi.encodeWithSignature("owner()")
        );
        require(success && abi.decode(data, (address)) == msg.sender, "Caller is not owner");
        require(implementation_ != address(0), "Invalid implementation address");
        ++nonce;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    /**
     * @dev Returns the owner token chainId, contract address, and token id.
     *      Defined in proxy because to prevent malicious implementations from
     *      spoofing a different token.
     */
    function token() external view returns (uint256, address, uint256) {
        return ERC6551AccountByteCode.token();
    }

}
