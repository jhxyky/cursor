// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/NFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTMarketplaceTest is Test {
    MyNFT public nft;
    NFTMarketplaceV1 public marketplaceV1;
    NFTMarketplaceV2 public marketplaceV2;
    ERC1967Proxy public proxy;

    address public owner;
    address public seller;
    address public buyer;

    uint256 public constant MARKETPLACE_FEE = 250; // 2.5%

    function setUp() public {
        // 设置测试账户
        owner = makeAddr("owner");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        vm.deal(buyer, 100 ether);

        // 部署 NFT 合约
        MyNFT nftImpl = new MyNFT();
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImpl),
            abi.encodeWithSelector(MyNFT.initialize.selector, "TestNFT", "TNFT")
        );
        nft = MyNFT(address(nftProxy));

        // 部署市场合约 V1
        NFTMarketplaceV1 marketplaceImpl = new NFTMarketplaceV1();
        proxy = new ERC1967Proxy(
            address(marketplaceImpl),
            abi.encodeWithSelector(NFTMarketplaceV1.initialize.selector, MARKETPLACE_FEE)
        );
        marketplaceV1 = NFTMarketplaceV1(address(proxy));

        // 铸造 NFT 给卖家
        vm.startPrank(owner);
        nft.safeMint(seller, 1);
        vm.stopPrank();
    }

    function test_ListAndBuyNFT() public {
        uint256 price = 1 ether;
        uint256 fee = (price * MARKETPLACE_FEE) / 10000;
        uint256 sellerProceeds = price - fee;

        // 卖家授权并上架 NFT
        vm.startPrank(seller);
        nft.approve(address(marketplaceV1), 1);
        marketplaceV1.listNFT(address(nft), 1, price);
        vm.stopPrank();

        // 检查上架状态
        (address listedSeller,,, uint256 listedPrice, bool isActive) = marketplaceV1.listings(address(nft), 1);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);
        assertTrue(isActive);

        // 买家购买 NFT
        vm.startPrank(buyer);
        marketplaceV1.buyNFT{value: price}(address(nft), 1);
        vm.stopPrank();

        // 验证 NFT 转移
        assertEq(nft.ownerOf(1), buyer);

        // 验证资金转移
        assertEq(seller.balance, sellerProceeds);
        assertEq(owner.balance, fee);
    }

    function test_UpgradeToV2() public {
        // 部署 V2 实现合约
        NFTMarketplaceV2 marketplaceImplV2 = new NFTMarketplaceV2();

        // 升级到 V2
        vm.prank(owner);
        NFTMarketplaceV1(address(proxy)).upgradeTo(address(marketplaceImplV2));

        // 验证升级后的合约
        marketplaceV2 = NFTMarketplaceV2(address(proxy));
        
        // 验证状态保持
        assertEq(marketplaceV2.marketplaceFee(), MARKETPLACE_FEE);

        // 测试新功能：签名上架
        uint256 price = 1 ether;
        uint256 nonce = 1;

        // 准备签名数据
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                address(nft),
                uint256(1),
                price,
                nonce,
                block.chainid
            )
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        uint256 sellerPrivateKey = 1;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 设置 seller 为私钥 1 对应的地址
        seller = vm.addr(sellerPrivateKey);
        
        // 重新铸造 NFT 给新的 seller
        vm.prank(owner);
        nft.safeMint(seller, 2);

        // 卖家使用签名上架 NFT
        vm.startPrank(seller);
        nft.approve(address(marketplaceV2), 2);
        marketplaceV2.listNFTWithSignature(
            address(nft),
            2,
            price,
            nonce,
            signature
        );
        vm.stopPrank();

        // 验证上架状态
        (address listedSeller,,, uint256 listedPrice, bool isActive) = marketplaceV2.listings(address(nft), 2);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);
        assertTrue(isActive);
    }
} 