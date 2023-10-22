// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "../../interfaces/IERC6551Account.sol";
import "../../interfaces/IERC6551Executable.sol";
import "../../lib/ERC6551AccountLib.sol";

/**
 * @title ERC6551AccountUpgradeable
 * @notice A lightweight smart contract wallet implementation that can be used by ERC6551AccountProxy
 */
contract ERC6551AccountUpgradeable is
    IERC165,
    IERC721Receiver,
    IERC1155Receiver,
    IERC6551Account,
    IERC6551Executable,
    IERC1271
{
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    uint256 public state;

    receive() external payable {}

    /**
     * @dev {See IERC6551Executable-execute}
     */
    function execute(address _target, uint256 _value, bytes calldata _data, uint8 _operation)
        external
        payable
        override
        returns (bytes memory _result)
    {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        require(_operation == 0, "Only call operations are supported");
        ++state;
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, _result) = _target.call{value: _value}(_data);
        require(success, string(_result));
        return _result;
    }

    /**
     * @dev Upgrades the implementation. Only the token owner can call this.
     */
    function upgrade(address implementation_) external virtual {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        require(implementation_ != address(0), "Invalid implementation address");
        ++state;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        virtual
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function onERC721Received(address, address, uint256 receivedTokenId, bytes memory)
        external
        view
        virtual
        returns (bytes4)
    {
        _revertIfOwnershipCycle(msg.sender, receivedTokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        external
        view
        virtual
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return (
            interfaceId == type(IERC6551Account).interfaceId
                || interfaceId == type(IERC6551Executable).interfaceId
                || interfaceId == type(IERC1155Receiver).interfaceId
                || interfaceId == type(IERC721Receiver).interfaceId
                || interfaceId == type(IERC165).interfaceId
        );
    }

    /**
     * @dev {See IERC6551Account-token}
     */
    function token() public view virtual override returns (uint256, address, uint256) {
        return ERC6551AccountLib.token();
    }

    function owner() public view virtual returns (address) {
        (uint256 chainId, address contractAddress, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);
        return IERC721(contractAddress).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view virtual returns (bool) {
        return signer == owner();
    }

    /**
     * @dev Helper method to check if a received token is in the ownership chain of the wallet.
     * @param receivedTokenAddress The address of the token being received.
     * @param receivedTokenId The ID of the token being received.
     */
    function _revertIfOwnershipCycle(address receivedTokenAddress, uint256 receivedTokenId)
        internal
        view
        virtual
    {
        (uint256 _chainId, address _contractAddress, uint256 _tokenId) = token();
        require(
            _chainId != block.chainid || receivedTokenAddress != _contractAddress
                || receivedTokenId != _tokenId,
            "Cannot own yourself"
        );

        address currentOwner = owner();
        require(currentOwner != address(this), "Token in ownership chain");
        uint256 depth = 0;
        while (currentOwner.code.length > 0) {
            try IERC6551Account(payable(currentOwner)).token() returns (
                uint256 chainId, address contractAddress, uint256 tokenId
            ) {
                require(
                    chainId != block.chainid || contractAddress != receivedTokenAddress
                        || tokenId != receivedTokenId,
                    "Token in ownership chain"
                );
                // Advance up the ownership chain
                currentOwner = IERC721(contractAddress).ownerOf(tokenId);
                require(currentOwner != address(this), "Token in ownership chain");
            } catch {
                break;
            }
            unchecked {
                ++depth;
            }
            if (depth == 5) revert("Ownership chain too deep");
        }
    }
}
