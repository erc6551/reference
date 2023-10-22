// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/ERC6551Registry.sol";
import "../src/lib/ERC6551AccountLib.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC6551Account.sol";

import "../src/interfaces/IERC6551Executable.sol";

contract ERC6551AccountLibTest is Test {
    ERC6551Registry public registry;
    MockERC6551Account public implementation;

    function setUp() public {
        registry = new ERC6551Registry();
        implementation = new MockERC6551Account();
    }

    function testERC6551AccountLib() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        bytes32 salt = bytes32(uint256(400));
        address deployedAccount;

        deployedAccount =
            registry.createAccount(address(implementation), salt, chainId, tokenAddress, tokenId);

        address libraryComputedAddress = ERC6551AccountLib.computeAddress(
            address(registry), address(implementation), salt, chainId, tokenAddress, tokenId
        );
        assertEq(deployedAccount, libraryComputedAddress);

        uint256 _chainId;
        address _tokenAddress;
        uint256 _tokenId;
        bytes32 _salt;

        (_salt, _chainId, _tokenAddress, _tokenId) = ERC6551AccountLib.context(deployedAccount);
        assertEq(_chainId, chainId);
        assertEq(_tokenAddress, tokenAddress);
        assertEq(_tokenId, tokenId);
        assertEq(_salt, salt);

        (_chainId, _tokenAddress, _tokenId) = ERC6551AccountLib.token(deployedAccount);
        assertEq(_chainId, chainId);
        assertEq(_tokenAddress, tokenAddress);
        assertEq(_tokenId, tokenId);

        _salt = ERC6551AccountLib.salt(deployedAccount);
        assertEq(_salt, salt);

        assertEq(
            ERC6551AccountLib.isERC6551Account(
                deployedAccount, address(implementation), address(registry)
            ),
            true
        );

        MockERC6551Account accountInstance = MockERC6551Account(payable(deployedAccount));

        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, chainId);
        assertEq(tokenAddress_, tokenAddress);
        assertEq(tokenId_, tokenId);

        assertEq(salt, accountInstance.salt());
    }
}
