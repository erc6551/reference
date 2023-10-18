// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC6551Registry {
    /**
     * @dev The registry MUST emit the ERC6551AccountCreated event upon successful account creation.
     */
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev The registry MUST revert with AccountCreationFailed error if the create2 operation fails.
     */
    error AccountCreationFailed();

    /**
     * @dev Creates a token bound account for a non-fungible token.
     *
     * If account has already been created, returns the account address without calling create2.
     *
     * If initData is not empty and account has not yet been created, calls account with
     * provided initData after creation.
     *
     * Emits ERC6551AccountCreated event
     *
     * @return account The address of the token bound account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    /**
     * @dev Returns the computed token bound account address for a non-fungible token.
     *
     * @return account The address of the token bound account
     */
    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}

contract ERC6551Registry is IERC6551Registry {
    function createAccount(
        address, // implementation
        bytes32, // salt
        uint256, // chainId
        address, // tokenContract
        uint256 // tokenId
    ) external returns (address) {
        assembly {
            // Memory Layout:
            // ----
            // 0x00   0xff                           (1 byte)
            // 0x01   registry (address)             (20 bytes)
            // 0x15   salt (bytes32)                 (32 bytes)
            // 0x35   Bytecode Hash (bytes32)        (32 bytes)
            // ----
            // 0x55   ERC-1167 Constructor + Header  (20 bytes)
            // 0x69   implementation (address)       (20 bytes)
            // 0x5D   ERC-1167 Footer                (15 bytes)
            // 0x8C   salt (uint256)                 (32 bytes)
            // 0xAC   chainId (uint256)              (32 bytes)
            // 0xCC   tokenContract (address)        (32 bytes)
            // 0xEC   tokenId (uint256)              (32 bytes)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            calldatacopy(0x69, 0x10, 0x14) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytedcode)
            calldatacopy(0x15, 0x24, 0x20) // salt
            mstore(0x01, shl(96, address())) // registry address
            mstore8(0x00, 0xff) // 0xFF

            // Compute account address
            let computed := shr(96, shl(96, keccak256(0, 0x55)))

            // Return computed account address if already deployed
            if gt(extcodesize(computed), 0) {
                mstore(0x00, computed)
                return(0x00, 0x20)
            }

            // Deploy account contract
            let deployed := create2(0, 0x55, 0xb7, calldataload(0x24))

            // Revert if the deployment fails
            if iszero(deployed) {
                mstore(0x00, 0x20188a59) // `AccountCreationFailed()`
                revert(0x1c, 0x04)
            }

            // Store account address in memory before salt and chainId
            mstore(0x6c, deployed)

            // Emit the ERC6551AccountCreated event
            log4(
                0x6c,
                0x60,
                // `ERC6551AccountCreated(address,address,bytes32,uint256,address,uint256)`
                0x79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf88722,
                calldataload(0x04), // implementation
                calldataload(0x64), // tokenContract
                calldataload(0x84) // tokenId
            )

            // Return the account address
            return(0x6c, 0x20)
        }
    }

    function account(
        address, // implementation
        bytes32, // salt
        uint256, // chainId
        address, // tokenContract
        uint256 // tokenId
    ) external view returns (address) {
        assembly {
            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            calldatacopy(0x69, 0x10, 0x14) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytedcode)
            calldatacopy(0x15, 0x24, 0x20) // salt
            mstore(0x01, shl(96, address())) // registry address
            mstore8(0, 0xff) // 0xFF

            // Store computed account address in memory
            mstore(0, shr(96, shl(96, keccak256(0, 0x55))))

            // Return computed account address
            return(0x00, 0x20)
        }
    }
}
