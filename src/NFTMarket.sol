// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTMarket
 * @dev NFT 交易市场合约，支持使用任意 ERC20 代币购买 NFT
 * 主要功能：
 * 1. 上架 NFT 并设定 ERC20 代币价格
 * 2. 使用 ERC20 代币购买 NFT
 * 3. 取消 NFT 上架
 */
contract NFTMarket is Ownable, ReentrancyGuard {
    /**
     * @dev NFT 上架信息结构体
     * @param seller NFT 卖家地址
     * @param token 支付代币地址（ERC20）
     * @param price NFT 价格（以 ERC20 代币计价）
     * @param isActive 是否正在上架
     */
    struct Listing {
        address seller;
        address token;
        uint256 price;
        bool isActive;
    }

    /**
     * @dev NFT 上架信息映射
     * 第一层映射：NFT 合约地址 => Token ID => 上架信息
     */
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    /**
     * @dev NFT 上架事件
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * @param seller 卖家地址
     * @param token 支付代币地址
     * @param price NFT 价格
     */
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address token,
        uint256 price
    );
    
    /**
     * @dev NFT 购买事件
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * @param buyer 买家地址
     * @param seller 卖家地址
     * @param token 支付代币地址
     * @param price 成交价格
     */
    event NFTPurchased(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        address token,
        uint256 price
    );
    
    /**
     * @dev NFT 取消上架事件
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * @param seller 卖家地址
     */
    event NFTUnlisted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    /**
     * @dev 构造函数，设置合约拥有者
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev 上架 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * @param token 支付代币地址
     * @param price NFT 价格
     * 要求：
     * 1. 价格必须大于 0
     * 2. 代币地址不能为零地址
     * 3. 调用者必须已经授权合约转移其 NFT
     */
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

    /**
     * @dev 购买 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * 要求：
     * 1. NFT 必须正在上架
     * 2. 买家不能是卖家
     * 3. 买家必须已经授权合约转移足够的 ERC20 代币
     */
    function purchaseNFT(
        address nftContract,
        uint256 tokenId
    ) external nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 转移 ERC20 代币
        IERC20(listing.token).transferFrom(
            msg.sender,
            listing.seller,
            listing.price
        );
        
        // 转移 NFT
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

    /**
     * @dev 取消 NFT 上架
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * 要求：
     * 1. NFT 必须正在上架
     * 2. 调用者必须是卖家
     */
    function unlistNFT(
        address nftContract,
        uint256 tokenId
    ) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.sender == listing.seller, "Not the seller");
        
        // 将 NFT 返还给卖家
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        
        // 更新上架状态
        listing.isActive = false;
        
        emit NFTUnlisted(nftContract, tokenId, msg.sender);
    }

    /**
     * @dev 获取 NFT 上架信息
     * @param nftContract NFT 合约地址
     * @param tokenId NFT 的 Token ID
     * @return seller 卖家地址
     * @return token 支付代币地址
     * @return price NFT 价格
     * @return isActive 是否正在上架
     */
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