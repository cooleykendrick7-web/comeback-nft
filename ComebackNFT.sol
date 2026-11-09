// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * The $90 Million Comeback — Base Mainnet (Chain ID 8453)
 *
 * - ERC-721, exactly ONE token: tokenId 1. There is NO mint function.
 *   The single token is created once, in the constructor, and can never
 *   be created again or duplicated by anyone, including the creator.
 * - Recipient: hardcoded to Ken's wallet, no matter which account or
 *   factory contract performs the deployment (Ken's Coinbase Smart
 *   Wallet deploys through the public CREATE2 factory, so msg.sender
 *   in this constructor is the factory — never rely on it here).
 * - Royalty: ERC-2981, 10% (1000 bps) to Ken's wallet on resales that
 *   honor royalties.
 * - No admin: no owner powers, no pause, no upgrade, no burn.
 */
contract ComebackNFT {
    string public constant name = "The $90 Million Comeback";
    string public constant symbol = "90MC";
    uint256 public constant TOKEN_ID = 1;

    /// @notice Ken's wallet — receives the one and only token at deployment.
    address public constant RECIPIENT = 0xEf8fB653A0aB5b7f01D0CD0DcA07b2C1EE3196E3;

    string private _uri;
    address private _owner;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory tokenURI_) {
        _uri = tokenURI_;
        _owner = RECIPIENT;
        emit Transfer(address(0), RECIPIENT, TOKEN_ID);
    }

    // ---------- views ----------
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenId == TOKEN_ID, "nonexistent token");
        return _owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "zero address");
        return account == _owner ? 1 : 0;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId == TOKEN_ID, "nonexistent token");
        return _uri;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenId == TOKEN_ID, "nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /// @notice ERC-2981: 10% royalty to Ken's wallet.
    function royaltyInfo(uint256, uint256 salePrice) public pure returns (address, uint256) {
        return (RECIPIENT, (salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x2a55205a;   // ERC2981
    }

    // ---------- approvals ----------
    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ---------- transfers ----------
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isAuthorized(from, tokenId), "not authorized");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isAuthorized(from, tokenId), "not authorized");
        _transfer(from, to, tokenId);
        if (to.code.length > 0) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                    IERC721Receiver.onERC721Received.selector,
                "unsafe recipient"
            );
        }
    }

    function _isAuthorized(address from, uint256 tokenId) internal view returns (bool) {
        require(tokenId == TOKEN_ID, "nonexistent token");
        require(from == _owner, "from is not owner");
        return
            msg.sender == from ||
            _tokenApprovals[tokenId] == msg.sender ||
            _operatorApprovals[from][msg.sender];
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(to != address(0), "zero address");
        delete _tokenApprovals[tokenId];
        _owner = to;
        emit Transfer(from, to, tokenId);
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
