// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ERC6551AccountByteCode {
    bytes public constant creationCode =
        hex"60208038033d393d517f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5560f78060343d393df360003560e01c635c60da1b1461004e57363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e610049573d6000fd5b3d6000f35b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc543d5260203df3";

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
        bytes memory footer = new bytes(0x60);

        assembly {
            // copy 0x60 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0x97, 0xf7)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function salt() internal view returns (uint256) {
        bytes memory footer = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from beginning of footer
            extcodecopy(address(), add(footer, 0x20), 0x77, 0x97)
        }

        return abi.decode(footer, (uint256));
    }
}
