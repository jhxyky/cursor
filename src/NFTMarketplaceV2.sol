// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTMarketplaceV1.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title NFTMarketplaceV2
 * @dev NFT 市场合约第二版 - 添加签名上架功能
 */
contract NFTMarketplaceV2 is NFTMarketplaceV1 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // 用于防止重放攻击的 nonce 映射
    mapping(address => uint256) public nonces;

    event NonceUsed(address indexed user, uint256 nonce);

    struct SignedListing {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        uint256 nonce;
        uint256 deadline;
    }

    // 签名上架事件
    event NFTListedWithSignature(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        uint256 nonce
    );

    /**
     * @dev 通过签名上架 NFT
     * @param seller 卖家地址
     * @param nftContract NFT 合约地址
     * @param tokenId 代币 ID
     * @param price 价格
     * @param deadline 签名过期时间
     * @param signature 签名数据
     */
    function listNFTWithSignature(
        address seller,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external whenNotPaused {
        require(block.timestamp <= deadline, "Signature expired");
        
        uint256 currentNonce = nonces[seller];
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SignedListing(address nftContract,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)"),
                nftContract,
                tokenId,
                price,
                currentNonce,
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == seller, "Invalid signature");

        nonces[seller]++;
        emit NonceUsed(seller, currentNonce);

        // 验证 NFT 所有权和授权
        require(IERC721(nftContract).ownerOf(tokenId) == seller, "Not token owner");
        require(
            IERC721(nftContract).isApprovedForAll(seller, address(this)) ||
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "Not approved for marketplace"
        );

        // 转移 NFT 到市场合约
        IERC721(nftContract).safeTransferFrom(seller, address(this), tokenId);

        // 创建上架信息
        listings[nftContract][tokenId] = Listing({
            seller: seller,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        emit Listed(seller, nftContract, tokenId, price);

        emit NFTListedWithSignature(
            seller,
            nftContract,
            tokenId,
            price,
            currentNonce
        );
    }

    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /**
     * @dev 实现 UUPS 升级授权检查
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 