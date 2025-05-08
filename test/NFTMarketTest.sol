// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 测试用的NFT合约
contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

// 测试用的ERC20合约
contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract NFTMarketTest is Test {
    NFTMarket public market;
    TestNFT public nft;
    TestToken public token;
    address public seller;
    address public buyer;
    address public other;

    // 事件定义
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

    function setUp() public {
        market = new NFTMarket();
        nft = new TestNFT();
        token = new TestToken();
        
        seller = address(0x1);
        buyer = address(0x2);
        other = address(0x3);

        // 给测试账户一些代币
        token.transfer(seller, 1000 * 10**18);
        token.transfer(buyer, 1000 * 10**18);
        token.transfer(other, 1000 * 10**18);

        // 给卖家一个NFT
        nft.mint(seller, 1);
    }

    // 测试上架NFT
    function testListNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        vm.expectEmit(true, true, true, true);
        emit NFTListed(address(nft), 1, seller, address(token), 100);
        market.listNFT(address(nft), 1, address(token), 100);
        
        (address _seller, address _token, uint256 _price, bool _isActive) = market.getListing(address(nft), 1);
        assertEq(_seller, seller);
        assertEq(_token, address(token));
        assertEq(_price, 100);
        assertTrue(_isActive);
        vm.stopPrank();
    }

    // 测试上架失败情况
    function testListNFTFailures() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);

        // 测试零价格
        vm.expectRevert("Price must be greater than 0");
        market.listNFT(address(nft), 1, address(token), 0);

        // 测试无效代币地址
        vm.expectRevert("Invalid token address");
        market.listNFT(address(nft), 1, address(0), 100);
        vm.stopPrank();
    }

    // 测试购买NFT
    function testPurchaseNFT() public {
        // 先上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100);
        vm.stopPrank();

        // 购买NFT
        vm.startPrank(buyer);
        token.approve(address(market), 100);
        
        uint256 buyerBalanceBefore = token.balanceOf(buyer);
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        
        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(address(nft), 1, buyer, seller, address(token), 100);
        market.purchaseNFT(address(nft), 1);
        
        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(buyer), buyerBalanceBefore - 100);
        assertEq(token.balanceOf(seller), sellerBalanceBefore + 100);
        vm.stopPrank();
    }

    // 测试购买失败情况
    function testPurchaseNFTFailures() public {
        // 先上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100);
        vm.stopPrank();

        // 测试自己购买自己的NFT
        vm.startPrank(seller);
        token.approve(address(market), 100);
        vm.expectRevert("Cannot buy your own NFT");
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();

        // 测试重复购买
        vm.startPrank(buyer);
        token.approve(address(market), 100);
        market.purchaseNFT(address(nft), 1);
        vm.expectRevert("NFT is not for sale");
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
    }

    // 模糊测试
    function testFuzzListAndPurchase(
        uint256 price,
        address randomBuyer
    ) public {
        // 限制价格范围在 0.01-10000 之间
        price = bound(price, 0.01 ether, 10000 ether);
        // 确保买家不是零地址
        vm.assume(randomBuyer != address(0));
        // 确保买家不是卖家
        vm.assume(randomBuyer != seller);

        // 给买家一些代币
        token.transfer(randomBuyer, price);

        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), price);
        vm.stopPrank();

        // 购买NFT
        vm.startPrank(randomBuyer);
        token.approve(address(market), price);
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();

        // 验证NFT所有权
        assertEq(nft.ownerOf(1), randomBuyer);
    }

    // 测试合约中不会有Token持仓
    function testNoTokenBalance() public {
        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100);
        vm.stopPrank();

        // 购买NFT
        vm.startPrank(buyer);
        token.approve(address(market), 100);
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();

        // 验证市场合约中没有Token余额
        assertEq(token.balanceOf(address(market)), 0);
    }
} 