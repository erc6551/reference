// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "sstore2/utils/Bytecode.sol";

library ERC6551AccountByteCode {
    bytes public constant creationCode =
        hex"60208038033d393d517f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5560f78060343d393df3363d3d3760003560e01c635c60da1b1461004e573d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e610049573d6000fd5b3d6000f35b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc543d5260203df3";

    function createCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                creationCode,
                abi.encode(salt_, chainId_, tokenContract_, tokenId_, implementation_)
            );
    }

    function token()
        internal
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        // codeAt start = creationCode.length-20
        // codeAt end = creationCode.length+76
        return
            abi.decode(
                Bytecode.codeAt(address(this), 151, 247),
                (uint256, address, uint256)
            );
    }

    function salt() internal view returns (uint256) {
        // codeAt start = creationCode.length-52
        // codeAt end = creationCode.length-20
        return abi.decode(Bytecode.codeAt(address(this), 119, 151), (uint256));
    }
}
