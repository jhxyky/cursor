// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTMarketV2
 * @dev 优化版本的 NFT 交易市场合约
 */
contract NFTMarketV2 is Ownable, ReentrancyGuard {
    // 使用更紧凑的数据结构，将 bool 和 address 打包在一起
    struct Listing {
        uint96 price;      // 使用 uint96 以允许与 address 打包
        address seller;    // 20 bytes
        address token;     // 20 bytes
        bool isActive;     // 1 byte
    }

    // 使用 bytes32 作为键来减少存储槽的使用
    mapping(bytes32 => Listing) private _listings;
    
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address token,
        uint256 price
    );
    
    event NFTPurchased(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        address token,
        uint256 price
    );
    
    event NFTUnlisted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    constructor() Ownable(msg.sender) {}

    // 内部函数：生成存储键
    function _getListingKey(address nftContract, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }

    function listNFT(
        address nftContract,
        uint256 tokenId,
        address token,
        uint256 price
    ) external {
        require(price > 0 && price <= type(uint96).max, "Invalid price");
        require(token != address(0), "Invalid token address");
        
        bytes32 key = _getListingKey(nftContract, tokenId);
        require(!_listings[key].isActive, "Already listed");
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        _listings[key] = Listing({
            price: uint96(price),
            seller: msg.sender,
            token: token,
            isActive: true
        });
        
        emit NFTListed(nftContract, tokenId, msg.sender, token, price);
    }

    function purchaseNFT(
        address nftContract,
        uint256 tokenId
    ) external nonReentrant {
        bytes32 key = _getListingKey(nftContract, tokenId);
        Listing storage listing = _listings[key];
        
        require(listing.isActive, "Not for sale");
        require(msg.sender != listing.seller, "Cannot buy own NFT");
        
        // 缓存变量以减少存储读取
        address seller = listing.seller;
        address token = listing.token;
        uint96 price = listing.price;
        
        // 先更新状态，防止重入
        listing.isActive = false;
        
        // 转移代币和 NFT
        IERC20(token).transferFrom(msg.sender, seller, price);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        emit NFTPurchased(nftContract, tokenId, msg.sender, seller, token, price);
    }

    function unlistNFT(
        address nftContract,
        uint256 tokenId
    ) external {
        bytes32 key = _getListingKey(nftContract, tokenId);
        Listing storage listing = _listings[key];
        
        require(listing.isActive, "Not for sale");
        require(msg.sender == listing.seller, "Not the seller");
        
        listing.isActive = false;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        emit NFTUnlisted(nftContract, tokenId, msg.sender);
    }

    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (
        address seller,
        address token,
        uint256 price,
        bool isActive
    ) {
        Listing storage listing = _listings[_getListingKey(nftContract, tokenId)];
        return (
            listing.seller,
            listing.token,
            listing.price,
            listing.isActive
        );
    }
} 