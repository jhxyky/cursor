// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title JiaoNFTMarket
 * @dev NFT交易市场合约，支持使用JiaoToken购买NFT
 * 主要功能：
 * 1. 上架NFT并设定代币价格
 * 2. 使用代币购买NFT
 * 3. 取消NFT上架
 * 4. 白名单签名授权购买NFT
 */
contract JiaoNFTMarket is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /**
     * @dev NFT上架信息结构体
     * @param seller NFT卖家地址
     * @param token 支付代币地址（ERC20）
     * @param price NFT价格（以ERC20代币计价）
     * @param isActive 是否正在上架
     */
    struct Listing {
        address seller;
        address token;
        uint256 price;
        bool isActive;
    }

    /**
     * @dev NFT上架信息映射
     * 第一层映射：NFT合约地址 => Token ID => 上架信息
     */
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // 白名单签名者(项目方)
    address public whitelistSigner;
    
    // 已使用的签名记录(防止重放攻击)
    mapping(bytes => bool) public usedSignatures;
    
    /**
     * @dev NFT上架事件
     */
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address token,
        uint256 price
    );
    
    /**
     * @dev NFT购买事件
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
     * @dev NFT取消上架事件
     */
    event NFTUnlisted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    /**
     * @dev 构造函数，设置合约拥有者和白名单签名者
     */
    constructor(address _whitelistSigner) Ownable(msg.sender) {
        whitelistSigner = _whitelistSigner;
    }

    /**
     * @dev 设置白名单签名者
     * @param _whitelistSigner 新的签名者地址
     */
    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        require(_whitelistSigner != address(0), "Invalid signer address");
        whitelistSigner = _whitelistSigner;
    }

    /**
     * @dev 上架NFT
     * @param nftContract NFT合约地址
     * @param tokenId NFT的Token ID
     * @param token 支付代币地址
     * @param price NFT价格
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
     * @dev 购买NFT(普通购买)
     * @param nftContract NFT合约地址
     * @param tokenId NFT的Token ID
     */
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
    
    /**
     * @dev 白名单授权购买NFT
     * @param nftContract NFT合约地址
     * @param tokenId NFT的Token ID
     * @param deadline 签名有效期
     * @param signature 白名单签名
     */
    function permitBuy(
        address nftContract,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Signature expired");
        require(!usedSignatures[signature], "Signature already used");
        
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT is not for sale");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 验证白名单签名
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            nftContract,
            tokenId,
            deadline
        ));
        
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);
        
        require(recoveredSigner == whitelistSigner, "Invalid signature");
        
        // 标记签名已使用
        usedSignatures[signature] = true;
        
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

    /**
     * @dev 取消NFT上架
     * @param nftContract NFT合约地址
     * @param tokenId NFT的Token ID
     */
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

    /**
     * @dev 获取NFT上架信息
     * @param nftContract NFT合约地址
     * @param tokenId NFT的Token ID
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