// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockERC721", "M721") {}

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }
}
