// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MerkleNFT.sol";
import "./MerkleToken.sol";
import "./MerkleProofHelper.sol";

/**
 * @title AirdropMerkleNFTMarket
 * @dev NFT 市场合约，支持白名单验证和折扣购买
 * 
 * 主要功能：
 * 1. 白名单用户可以以折扣价购买 NFT
 * 2. 使用 Merkle 树进行白名单验证
 * 3. 支持 ERC20 代币支付
 * 4. 支持 ERC20 Permit 功能，免 gas 授权
 */
contract AirdropMerkleNFTMarket is Ownable {
    // NFT 合约实例
    MerkleNFT public nft;
    // 支付代币合约实例
    MerkleToken public token;
    // Merkle 树根节点
    bytes32 public merkleRoot;
    
    // NFT 价格映射：tokenId => price
    mapping(uint256 => uint256) public nftPrices;
    // 用户已购买记录：user => tokenId => claimed
    mapping(address => mapping(uint256 => bool)) public hasClaimed;
    
    // 折扣比例（50%）
    uint256 public constant DISCOUNT_RATE = 50;
    
    /**
     * @dev NFT 上架事件
     * @param tokenId NFT 的 token ID
     * @param price NFT 的原始价格
     */
    event NFTListed(uint256 indexed tokenId, uint256 price);

    /**
     * @dev NFT 购买事件
     * @param buyer 购买者地址
     * @param tokenId 购买的 NFT token ID
     * @param price 实际支付价格（已折扣）
     */
    event NFTClaimed(address indexed buyer, uint256 indexed tokenId, uint256 price);
    
    /**
     * @dev 构造函数
     * @param _nft NFT 合约地址
     * @param _token 支付代币合约地址
     * @param _merkleRoot 白名单 Merkle 树根节点
     */
    constructor(
        address _nft,
        address _token,
        bytes32 _merkleRoot
    ) Ownable(msg.sender) {
        nft = MerkleNFT(_nft);
        token = MerkleToken(_token);
        merkleRoot = _merkleRoot;
    }
    
    /**
     * @dev 更新 Merkle 树根节点
     * @param _merkleRoot 新的根节点
     * 
     * 只有合约拥有者可以调用此函数
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    /**
     * @dev 上架 NFT
     * @param tokenId 要上架的 NFT token ID
     * @param price NFT 的原始价格
     * 
     * 要求：
     * 1. 只有合约拥有者可以调用
     * 2. NFT 必须在市场合约中
     */
    function listNFT(uint256 tokenId, uint256 price) external onlyOwner {
        require(nft.ownerOf(tokenId) == address(this), "NFT not owned by market");
        nftPrices[tokenId] = price;
        emit NFTListed(tokenId, price);
    }
    
    /**
     * @dev 验证地址是否在白名单中
     * @param account 要验证的地址
     * @param proof Merkle 树证明路径
     * @return bool 是否在白名单中
     */
    function isWhitelisted(address account, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = MerkleProofHelper.getLeaf(account);
        return MerkleProofHelper.verifyProof(proof, merkleRoot, leaf);
    }
    
    /**
     * @dev 计算折扣后的价格
     * @param price 原始价格
     * @return uint256 折扣后的价格
     * 
     * 折扣计算公式：price * (100 - DISCOUNT_RATE) / 100
     */
    function getDiscountedPrice(uint256 price) public pure returns (uint256) {
        return (price * (100 - DISCOUNT_RATE)) / 100;
    }
    
    /**
     * @dev 使用 ERC20 Permit 进行预授权
     * @param owner 代币持有者地址
     * @param value 授权金额
     * @param deadline 授权截止时间
     * @param v 签名的 v 值
     * @param r 签名的 r 值
     * @param s 签名的 s 值
     * 
     * 允许用户通过签名进行授权，无需发送授权交易
     */
    function permitPrePay(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(owner, address(this), value, deadline, v, r, s);
    }
    
    /**
     * @dev 购买 NFT
     * @param tokenId 要购买的 NFT token ID
     * @param proof 白名单 Merkle 树证明
     * 
     * 要求：
     * 1. 用户必须在白名单中
     * 2. NFT 必须已上架
     * 3. 用户之前没有购买过此 NFT
     * 4. 用户必须有足够的代币余额和授权
     */
    function claimNFT(
        uint256 tokenId,
        bytes32[] calldata proof
    ) external {
        require(!hasClaimed[msg.sender][tokenId], "Already claimed");
        require(isWhitelisted(msg.sender, proof), "Not whitelisted");
        
        uint256 price = nftPrices[tokenId];
        require(price > 0, "NFT not listed");
        
        uint256 discountedPrice = getDiscountedPrice(price);
        require(token.transferFrom(msg.sender, address(this), discountedPrice), "Token transfer failed");
        
        nft.transferFrom(address(this), msg.sender, tokenId);
        hasClaimed[msg.sender][tokenId] = true;
        
        emit NFTClaimed(msg.sender, tokenId, discountedPrice);
    }
    
    /**
     * @dev 提取合约中的代币
     * 
     * 只有合约拥有者可以调用此函数
     * 将合约中的所有代币转移到合约拥有者地址
     */
    function withdrawToken() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Token transfer failed");
    }
} 