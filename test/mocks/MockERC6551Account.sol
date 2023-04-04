// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/introspection/IERC165.sol";

import "../../src/interfaces/IERC6551Account.sol";
import "../../src/lib/ERC6551AccountByteCode.sol";

contract MockERC6551Account is IERC165, IERC6551Account {
    uint256 public nonce;
    bool private _initialized;

    receive() external payable {}

    function initialize(bool val) external {
        if (!val) {
            revert("disabled");
        }
        _initialized = val;
    }

    function executeCall(address, uint256, bytes calldata) external payable returns (bytes memory) {
        revert("disabled");
    }

    function token() external view returns (uint256, address, uint256) {
        return ERC6551AccountByteCode.token();
    }

    function salt() external view returns (uint256) {
        return ERC6551AccountByteCode.salt();
    }

    function owner() public pure returns (address) {
        revert("disabled");
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        if (interfaceId == 0xffffffff) return false;
        return _initialized;
    }

    function codeLength() external view returns (uint256) {
        return ERC6551AccountByteCode.codeLength();
    }
}
