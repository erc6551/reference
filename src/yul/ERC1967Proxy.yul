object "ERC1967Proxy" {
    code {
        let contractStart := dataoffset("runtime")
        let contractEnd := add(datasize("runtime"), 0x80)
        let constructorStart := add(contractStart, contractEnd)

        datacopy(0, constructorStart, add(constructorStart, 0x20))
        sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, mload(0x0))

        datacopy(0, contractStart, contractEnd)
        return(0, contractEnd)
    }
    object "runtime" {
        code {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc), 0x0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            if iszero(success) {
                revert(0, returndatasize())
            }

            return(0, returndatasize())
        }
    }
}
