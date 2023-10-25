pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./Bytecode.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC6551Account.sol";

contract ExampleERC6551Account is IERC165, IERC1271, IERC6551Account {
    receive() external payable {}

    address public _prevOwner;
    address public _currOwner;

    function initialize() external returns (bool) {
        require(
            owner() == msg.sender,
            "only new owner could call this function"
        );
        if (_prevOwner == address(0)) {
            _prevOwner = _currOwner = msg.sender;
        } else {
            _prevOwner = _currOwner;
            _currOwner = msg.sender;
        }

        return true;
    }

    function unlockCircularLock() external returns (bool) {
        require(
            owner() == address(this),
            "circular lock condition is not present"
        );
        require(
            msg.sender == _prevOwner,
            "could only be called by previous owner"
        );
        (, address _tokenAddr, uint256 _tokenId) = token();
        IERC721(_tokenAddr).safeTransferFrom(
            address(this),
            _prevOwner,
            _tokenId
        );

        return true;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(
            msg.sender == owner() && _currOwner == owner(),
            "not owner or contract is not initialized"
        );

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
        public
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        )
    {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x60, length),
                (uint256, address, uint256)
            );
    }

    function executeCallTransferToken(
        address _to,
        address _tokenAddr,
        uint256 _amount
    ) external returns (bool) {
        require(
            msg.sender == owner() && _currOwner == owner(),
            "not owner or contract is not initialized"
        );
        bool success;
        success = IERC20(_tokenAddr).transfer(_to, _amount);
        if (!success) {
            return false;
        }
        return true;
    }

    function executeCallTransferERC721(
        address _to,
        address _tokenAddr,
        uint256 _tokenId
    ) external returns (bool success) {
        require(
            msg.sender == owner() && _currOwner == owner(),
            "not owner or contract is not initialized"
        );
        IERC721(_tokenAddr).safeTransferFrom(address(this), _to, _tokenId);
        success = true;
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}
