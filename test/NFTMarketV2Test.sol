// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarketV2.sol";
import "./mocks/TestNFT.sol";
import "./mocks/TestToken.sol";

contract NFTMarketV2Test is Test {
    NFTMarketV2 public market;
    TestNFT public nft;
    TestToken public token;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    function setUp() public {
        market = new NFTMarketV2();
        nft = new TestNFT();
        token = new TestToken();
        
        // 给测试账户铸造 NFT 和代币
        nft.mint(alice, 1);
        nft.mint(bob, 2);
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);
        token.mint(charlie, 1000 ether);
    }
    
    function testListNFT() public {
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100 ether);
        vm.stopPrank();
        
        (address seller, address tokenAddr, uint256 price, bool isActive) = market.getListing(address(nft), 1);
        assertEq(seller, alice);
        assertEq(tokenAddr, address(token));
        assertEq(price, 100 ether);
        assertTrue(isActive);
    }
    
    function testListNFTFailures() public {
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        
        // 测试零价格
        vm.expectRevert("Invalid price");
        market.listNFT(address(nft), 1, address(token), 0);
        
        // 测试零地址代币
        vm.expectRevert("Invalid token address");
        market.listNFT(address(nft), 1, address(0), 100 ether);
        
        // 测试未授权
        nft.approve(address(0), 1);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        market.listNFT(address(nft), 1, address(token), 100 ether);
        
        vm.stopPrank();
    }
    
    function testPurchaseNFT() public {
        // 先上架 NFT
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100 ether);
        vm.stopPrank();
        
        // 购买 NFT
        vm.startPrank(bob);
        token.approve(address(market), 100 ether);
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
        
        // 验证 NFT 所有权转移
        assertEq(nft.ownerOf(1), bob);
        
        // 验证代币余额变化
        assertEq(token.balanceOf(alice), 1100 ether); // 1000 + 100
        assertEq(token.balanceOf(bob), 900 ether);    // 1000 - 100
        
        // 验证上架状态
        (,,,bool isActive) = market.getListing(address(nft), 1);
        assertFalse(isActive);
    }
    
    function testPurchaseNFTFailures() public {
        // 先上架 NFT
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100 ether);
        vm.stopPrank();
        
        // 测试购买自己的 NFT
        vm.startPrank(alice);
        token.approve(address(market), 100 ether);
        vm.expectRevert("Cannot buy own NFT");
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
        
        // 测试购买未上架的 NFT
        vm.startPrank(bob);
        token.approve(address(market), 100 ether);
        vm.expectRevert("Not for sale");
        market.purchaseNFT(address(nft), 2);
        vm.stopPrank();
        
        // 测试代币余额不足
        vm.startPrank(charlie);
        token.approve(address(market), 100 ether);
        token.transfer(address(0), 950 ether); // 只留下 50 ether
        vm.expectRevert("ERC20: insufficient allowance");
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
    }
    
    function testNoTokenBalance() public {
        // 先上架 NFT
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), 100 ether);
        vm.stopPrank();
        
        // 创建一个没有代币的地址
        address noToken = address(0x4);
        vm.startPrank(noToken);
        token.approve(address(market), 100 ether);
        vm.expectRevert("ERC20: insufficient allowance");
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
    }
    
    function testFuzzListAndPurchase(uint256 price, address buyer) public {
        // 限制价格范围
        price = bound(price, 1, type(uint96).max);
        // 确保买家不是卖家
        vm.assume(buyer != alice);
        
        // 上架 NFT
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, address(token), price);
        vm.stopPrank();
        
        // 给买家铸造足够的代币
        token.mint(buyer, price);
        
        // 购买 NFT
        vm.startPrank(buyer);
        token.approve(address(market), price);
        market.purchaseNFT(address(nft), 1);
        vm.stopPrank();
        
        // 验证 NFT 所有权转移
        assertEq(nft.ownerOf(1), buyer);
        
        // 验证代币余额变化
        assertEq(token.balanceOf(alice), 1000 ether + price);
        assertEq(token.balanceOf(buyer), 0);
    }
} 