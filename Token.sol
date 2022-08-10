pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "IERC2981.sol";

/**
 * @title Sample NFT contract
 * @dev Extends ERC-721 NFT contract and implements ERC-2981
 */

contract Token is Ownable, ERC721, ERC721URIStorage {

    // Keep a mapping of token ids and corresponding IPFS hashes
    mapping(string => uint8) hashes;
    // Maximum amounts of mintable tokens
    uint256 public _maxSupply;

    address private _admin; 

    mapping(bytes32 => uint256) usedMessages;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant royaltiesPercentage = 10;
    address private _royaltiesReceiver;


    // Events
    event Mint(uint256 tokenId, address recipient);


    constructor(uint256 maxSupply, address admin, string memory name, string memory tag, address royaltiesReceiver) ERC721(name, tag) {
        _maxSupply = maxSupply;
        _admin = admin;
        _royaltiesReceiver = royaltiesReceiver;
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal view override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override(ERC721) {
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
    public view override(ERC721)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }



    function multiMint(address recipient, string[] memory hash, uint256 NFTcopiesNumber, uint256 time, bytes memory sig)
    external 
    returns (uint256[10] memory tokenId){
        require(verifyMessage(_admin,recipient,hash[0], NFTcopiesNumber, time, sig), "Unauthorized use" );
        bytes32  message = getMessageHash(recipient, NFTcopiesNumber, hash[0], time);
        require(usedMessages[message] != 1, "Already minted");
        uint256[10] memory tokenIds;
        for(uint256 i = 0; i < NFTcopiesNumber; i++){
            tokenIds[i] = mint(recipient, hash[i]);
            // mint(recipient, hash[i]);
        }
        usedMessages[message] = 1;
        return tokenIds;
    }


    function mint(address recipient, string memory hash)
    private 
    returns (uint256 tokenId)
    {
        require(_tokenSupply.current() <= _maxSupply, "All tokens minted");
        require(bytes(hash).length > 0); // dev: Hash can not be empty!
        uint256 newItemId = _tokenSupply.current() + 1;
        _tokenSupply.increment();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, hash);
        emit Mint(newItemId, recipient);
        return newItemId;
    }

        // use this function to get the hash of any string
    function getHash(string memory str) public pure returns (bytes32) {
        return getEthSignedHash(keccak256(abi.encodePacked(str)));
    }
    
    
    // take the keccak256 hashed message from the getHash function above and input into this function
    // this function prefixes the hash above with \x19Ethereum signed message:\n32 + hash
    // and produces a new hash signature
    function getEthSignedHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    
    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    public
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

    function verifyMessage(
        address _signer,
        address recipient, string memory hash, uint nftCopies, uint256 time,
        bytes memory signature
    )
        public pure returns (bool)
    {

        bytes32 hashMsg = getMessageHash(recipient, nftCopies, hash, time);
        bytes32 ethSignedMessageHash = getEthSignedHash(hashMsg);

        return verify(ethSignedMessageHash, signature) == _signer;
    }

    function getMessageHash(
        address recipient, uint nftCopies, string memory hash, uint256 time
    )
        public pure returns (bytes32)
    {

        // return getEthSignedHash(keccak256(abi.encodePacked(recipient, ";", hash, ";", nftCopies)));
        return keccak256(abi.encodePacked(recipient, ";", hash, ";", nftCopies, ";", time));
    } 

    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

}
