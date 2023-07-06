// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev the ERC-165 identifier for this interface is `0xe864c213`
interface IERC6551Account {
    /**
     * @dev Allows the account to receive Ether
     *
     * Accounts MUST implement a `receive` function.
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received.
     */
    receive() external payable;

    /**
     * @dev Returns the identifier of the non-fungible token which owns the account
     *
     * The return value of this function MUST be constant - it MUST NOT change
     * over time.
     *
     * @return chainId       The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId       The ID of the token
     */
    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        );

    /**
     * @dev Returns a value that is updated during every account transaction
     *
     * @return The current account state
     */
    function state() external view returns (uint256);

    /**
     * @dev Returns whether a given signer is authorized to act on behalf of the account
     *
     * MUST return the bytes4 magic value 0xd5f50582 if the given signer is valid
     *
     * By default, the holder of the non-fungible token which owns the account MUST be a valid
     * signer.
     *
     * Accounts MAY implement additional authorization logic which invalidates the holder as a
     * signer or grants signing permissions to other non-holder accounts
     *
     * @param  signer     The address to check signing authorization for
     * @return magicValue Value indicating whether the signer is valid
     */
    function isValidSigner(address signer) external view returns (bytes4 magicValue);
}
