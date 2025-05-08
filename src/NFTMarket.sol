// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarket is Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        address token;
        uint256 price;
        bool isActive;
    }

    // NFT合约地址 => Token ID => 上架信息
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // 上架事件
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address token,
        uint256 price
    );
    
    // 购买事件
    event NFTPurchased(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        address token,
        uint256 price
    );
    
    // 取消上架事件
    event NFTUnlisted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    constructor() Ownable(msg.sender) {}

    // 上架NFT
    function listNFT(
        address nftContract,
        uint256 tokenId,
        address token,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");
        require(token != address(0), "Invalid token address");
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            token: token,
            price: price,
            isActive: true
        });
        
        emit NFTListed(nftContract, tokenId, msg.sender, token, price);
    }

    // 购买NFT
    function purchaseNFT(
        address nftContract,
        uint256 tokenId
    ) external nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 转移ERC20代币
        IERC20(listing.token).transferFrom(
            msg.sender,
            listing.seller,
            listing.price
        );
        
        // 转移NFT
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        
        // 更新上架状态
        listing.isActive = false;
        
        emit NFTPurchased(
            nftContract,
            tokenId,
            msg.sender,
            listing.seller,
            listing.token,
            listing.price
        );
    }

    // 取消上架
    function unlistNFT(
        address nftContract,
        uint256 tokenId
    ) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.sender == listing.seller, "Not the seller");
        
        // 将NFT返还给卖家
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        
        // 更新上架状态
        listing.isActive = false;
        
        emit NFTUnlisted(nftContract, tokenId, msg.sender);
    }

    // 获取上架信息
    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (
        address seller,
        address token,
        uint256 price,
        bool isActive
    ) {
        Listing storage listing = listings[nftContract][tokenId];
        return (
            listing.seller,
            listing.token,
            listing.price,
            listing.isActive
        );
    }
} 