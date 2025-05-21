// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * @title NFTMarketplaceV1
 * @dev NFT 市场合约第一版 - 基础功能实现
 */
contract NFTMarketplaceV1 is 
    Initializable, 
    PausableUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    ERC721Holder 
{
    // 存储 NFT 上架信息的结构体
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    // NFT 上架事件
    event Listed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );

    // NFT 下架事件
    event Delisted(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    // NFT 售出事件
    event Sold(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    // 市场费率（以基点表示，1% = 100）
    uint256 public marketplaceFee;
    // 市场费用接收地址
    address public feeReceiver;
    
    // 存储所有上架的 NFT
    mapping(address => mapping(uint256 => Listing)) public listings;

    event FeeUpdated(uint256 newFee);
    event FeeReceiverUpdated(address newFeeReceiver);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化合约
     * @param initialOwner 初始所有者
     * @param initialFee 初始市场费率（基点）
     * @param initialFeeReceiver 初始市场费用接收地址
     */
    function initialize(address initialOwner, uint256 initialFee, address initialFeeReceiver) initializer public {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        require(initialFee <= 1000, "Fee too high"); // 最大 10%
        marketplaceFee = initialFee;
        feeReceiver = initialFeeReceiver;
    }

    /**
     * @dev 上架 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId 代币 ID
     * @param price 价格（以 wei 为单位）
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external whenNotPaused {
        require(price > 0, "Price must be greater than 0");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not token owner"
        );
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this) ||
            IERC721(nftContract).isApprovedForAll(msg.sender, address(this)),
            "Not approved for marketplace"
        );

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        emit Listed(msg.sender, nftContract, tokenId, price);
    }

    /**
     * @dev 下架 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId 代币 ID
     */
    function delistNFT(
        address nftContract,
        uint256 tokenId
    ) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "Not listed");
        require(listing.seller == msg.sender, "Not seller");

        listing.isActive = false;
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Delisted(msg.sender, nftContract, tokenId);
    }

    /**
     * @dev 购买 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId 代币 ID
     */
    function buyNFT(
        address nftContract,
        uint256 tokenId
    ) external payable whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "Not listed");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.isActive = false;

        uint256 feeAmount = (listing.price * marketplaceFee) / 10000;
        uint256 sellerAmount = listing.price - feeAmount;

        (bool feeSuccess, ) = feeReceiver.call{value: feeAmount}("");
        require(feeSuccess, "Fee transfer failed");

        (bool sellerSuccess, ) = listing.seller.call{value: sellerAmount}("");
        require(sellerSuccess, "Seller transfer failed");

        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        // 退还多余的 ETH
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - listing.price}("");
            require(refundSuccess, "Refund failed");
        }

        emit Sold(listing.seller, msg.sender, nftContract, tokenId, listing.price);
    }

    /**
     * @dev 更新市场费率
     * @param newFee 新的市场费率（基点）
     */
    function updateMarketplaceFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // 最大 10%
        marketplaceFee = newFee;
        emit FeeUpdated(newFee);
    }

    /**
     * @dev 更新市场费用接收地址
     * @param newFeeReceiver 新的市场费用接收地址
     */
    function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "Invalid address");
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    /**
     * @dev 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev 实现 UUPS 升级授权检查
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 