// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

error InvalidImplementation();

contract ERC6551AccountProxy is Proxy, ERC1967Upgrade {
    address immutable defaultImplementation;

    constructor(address _defaultImplementation) {
        if (_defaultImplementation == address(0)) revert InvalidImplementation();
        defaultImplementation = _defaultImplementation;
    }

    function _implementation() internal view virtual override returns (address) {
        address implementation = ERC1967Upgrade._getImplementation();

        if (implementation == address(0)) return defaultImplementation;

        return implementation;
    }

    function _beforeFallback() internal virtual override {
        super._beforeFallback();
        if (msg.data.length == 0) {
            if (ERC1967Upgrade._getImplementation() == address(0)) {
                ERC1967Upgrade._upgradeTo(defaultImplementation);
                _delegate(defaultImplementation);
            }
        }
    }
}
