// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

import "../simple/SimpleERC6551Account.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/metatx/ERC2771Context.sol";

contract InitializableERC6551Account is SimpleERC6551Account, ERC2771Context {
    address public creator;

    constructor(address registry) ERC2771Context(registry) {}

    function initialize() public {
        (, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();
        address _creator = _msgSender();

        require(
            _creator == IERC721(tokenContract).ownerOf(tokenId),
            "Only initializable by token holder"
        );

        creator = _creator;
    }
}
