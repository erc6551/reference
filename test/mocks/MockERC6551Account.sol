// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "../../src/interfaces/IERC6551Account.sol";
import "../../src/interfaces/IERC6551Executable.sol";
import "../../src/lib/ERC6551AccountLib.sol";

contract MockERC6551Account is IERC165, IERC6551Account, IERC6551Executable {
    uint256 public state;
    bool private _initialized;

    receive() external payable {}

    function initialize(bool val) external {
        if (!val) {
            revert("disabled");
        }
        _initialized = val;
    }

    function execute(address, uint256, bytes calldata, uint8)
        external
        payable
        returns (bytes memory)
    {
        revert("disabled");
    }

    function token() external view returns (uint256, address, uint256) {
        return ERC6551AccountLib.token();
    }

    function salt() external view returns (bytes32) {
        return ERC6551AccountLib.salt();
    }

    function owner() public pure returns (address) {
        revert("disabled");
    }

    function isValidSigner(address, bytes calldata) public pure returns (bytes4) {
        revert("disabled");
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        if (interfaceId == 0xffffffff) return false;
        return _initialized;
    }
}
