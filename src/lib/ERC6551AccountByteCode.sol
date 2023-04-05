// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ERC6551AccountByteCode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode
    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) private view returns (bytes memory oCode) {
        uint256 csize = _addr.code.length;
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }

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
                codeAt(address(this), 151, 247),
                (uint256, address, uint256)
            );
    }

    function salt() internal view returns (uint256) {
        // codeAt start = creationCode.length-52
        // codeAt end = creationCode.length-20
        return abi.decode(codeAt(address(this), 119, 151), (uint256));
    }
}
