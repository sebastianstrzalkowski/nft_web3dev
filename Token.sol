pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Sample NFT contract
 * @dev Extends ERC-721 NFT contract and implements ERC-2981
 */

contract Token is Ownable, ERC721Enumerable, ERC721URIStorage {

    // Keep a mapping of token ids and corresponding IPFS hashes
    mapping(string => uint8) hashes;
    // Maximum amounts of mintable tokens
    uint256 public _maxSupply;

    address private _admin; 


    // Events
    event Mint(uint256 tokenId, address recipient);


    constructor(uint256 maxSupply, address admin, string memory name, string memory tag) ERC721(name, tag) {
        _maxSupply = maxSupply;
        _admin = admin;
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal view override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId)
    internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId - the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId)
    public view override(ERC721, ERC721URIStorage)
    returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address
    function tokensOfOwner(address _owner) external view
    returns(uint256[] memory ownerTokens ) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i=0; i<tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function multiMint(address recipient, string[] memory hash, uint256 NFTcopiesNumber, bytes32 message, bytes memory sig)
    external 
    returns (uint256[] memory tokenId){
        require(recoverSigner(message,sig) == _admin, "Unauthorized use" );
        uint256[] memory tokenIds;
        for(uint256 i = 0; i < NFTcopiesNumber; i++){
            tokenIds[i] = mint(recipient, hash[i]);
        }
        return tokenIds;
    }


    function mint(address recipient, string memory hash)
    private 
    returns (uint256 tokenId)
    {
        require(totalSupply() <= _maxSupply, "All tokens minted");
        require(bytes(hash).length > 0); // dev: Hash can not be empty!
        require(hashes[hash] != 1); // dev: Can't use the same hash twice
        hashes[hash] = 1;
        uint256 newItemId = totalSupply() + 1;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, hash);
        emit Mint(newItemId, recipient);
        return newItemId;
    }

    // /// @notice Mints tokens
    // /// @param recipient - the address to which the token will be transfered
    // /// @param hash - the IPFS hash of the token's resource
    // /// @return tokenId - the id of the token
    // function mint(address recipient, string memory hash, bytes32 message, bytes memory sig)
    // external 
    // returns (uint256 tokenId)
    // {
    //     require(totalSupply() <= _maxSupply, "All tokens minted");
    //     require(bytes(hash).length > 0); // dev: Hash can not be empty!
    //     require(hashes[hash] != 1); // dev: Can't use the same hash twice
    //     hashes[hash] = 1;
    //     uint256 newItemId = totalSupply() + 1;
    //     _safeMint(recipient, newItemId);
    //     _setTokenURI(newItemId, hash);
    //     emit Mint(newItemId, recipient);
    //     return newItemId;
    // }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {   
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
     }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

    return ecrecover(message, v, r, s);
    }


}
