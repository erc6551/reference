// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-contracts/utils/StorageSlot.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";

import "../../../../src/interfaces/IERC6551Account.sol";
import "../../../../src/lib/ERC6551AccountByteCode.sol";

/**
 * @title MaliciousERC6551AccountProxyImpl
 * @notice A malicious proxy implementation
 */
contract MaliciousERC6551AccountProxyImpl is IERC165, IERC721Receiver, IERC1155Receiver, IERC6551Account {
    // Padding for initializable values
    uint256 private _initializablePadding;
    uint256 private _nonce;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev {See IERC6551Account-token}
     */
    function token() external pure override returns (uint256, address, uint256) {
        return (100, address(200), 300);
    }

    /**
     * @dev {See IERC6551Account-owner}
     */
    function owner() public pure override returns (address) {
      return address(400);
    }

    /**
     * @dev {See IERC6551Account-nonce}
     */
    function nonce() external pure override returns (uint256) {
        return 0;
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
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, _result) = _target.call{value: _value}(_data);
        require(success, string(_result));
        emit TransactionExecuted(_target, _value, _data);
        return _result;
    }

    /**
     * @dev Upgrades the implementation.  Only the token owner can call this.
     */
    function upgrade(address implementation_) public {
        require(implementation_ != address(0), "Invalid implementation address");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    receive() external payable {}
}
