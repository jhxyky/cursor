// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract MemeFactoryTest is Test {
    MemeFactory public factory;
    
    address public owner = address(1); // 项目方地址
    address public creator = address(2); // Meme创建者
    address public buyer1 = address(3); // 代币购买者1
    address public buyer2 = address(4); // 代币购买者2

    // 测试参数
    string symbol = "PEPE";
    uint256 totalSupply = 1_000_000 * 10**18;
    uint256 perMint = 10_000 * 10**18;
    uint256 price = 0.01 ether;

    function setUp() public {
        // 给测试账户一些ETH
        vm.deal(owner, 10 ether);
        vm.deal(creator, 10 ether);
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);

        // 部署工厂合约
        vm.prank(owner);
        factory = new MemeFactory();
    }

    function test_DeployInscription() public {
        vm.prank(creator);
        address tokenAddress = factory.deployInscription(symbol, totalSupply, perMint, price);
        
        // 验证代币合约是否正确部署
        MemeToken token = MemeToken(tokenAddress);
        
        assertEq(token.name(), string(abi.encodePacked("Meme ", symbol)));
        assertEq(token.symbol(), symbol);
        assertEq(token.maxSupply(), totalSupply);
        assertEq(token.mintAmount(), perMint);
        assertEq(token.mintPrice(), price);
        assertEq(token.creator(), creator);
        assertEq(token.factory(), address(factory));
        assertEq(token.owner(), creator);
        assertEq(token.totalMinted(), 0);
    }
    
    function test_MintInscription() public {
        // 首先部署代币
        vm.prank(creator);
        address tokenAddress = factory.deployInscription(symbol, totalSupply, perMint, price);
        MemeToken token = MemeToken(tokenAddress);
        
        // 记录初始余额
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialCreatorBalance = creator.balance;
        uint256 initialBuyerBalance = buyer1.balance;
        
        // 买家铸造代币
        vm.prank(buyer1);
        factory.mintInscription{value: price}(tokenAddress);
        
        // 验证代币是否正确铸造给买家
        assertEq(token.balanceOf(buyer1), perMint);
        assertEq(token.totalMinted(), perMint);
        
        // 验证费用是否正确分配
        uint256 ownerFee = (price * 1) / 100; // 1%给项目方
        uint256 creatorFee = price - ownerFee; // 99%给创建者
        
        assertEq(owner.balance, initialOwnerBalance + ownerFee);
        assertEq(creator.balance, initialCreatorBalance + creatorFee);
        assertEq(buyer1.balance, initialBuyerBalance - price);
    }
    
    function test_MultipleMinting() public {
        // 部署代币
        vm.prank(creator);
        address tokenAddress = factory.deployInscription(symbol, totalSupply, perMint, price);
        MemeToken token = MemeToken(tokenAddress);
        
        // 铸造多次，直到达到总供应量
        uint256 mintCount = totalSupply / perMint;
        
        for(uint256 i = 0; i < mintCount; i++) {
            vm.prank(buyer1);
            factory.mintInscription{value: price}(tokenAddress);
            
            assertEq(token.totalMinted(), perMint * (i + 1));
        }
        
        // 再次铸造应该失败（超出总供应量）
        vm.prank(buyer2);
        vm.expectRevert("Exceeds total supply");
        factory.mintInscription{value: price}(tokenAddress);
    }
    
    function test_IncorrectPayment() public {
        // 部署代币
        vm.prank(creator);
        address tokenAddress = factory.deployInscription(symbol, totalSupply, perMint, price);
        
        // 支付金额不足应该失败
        vm.prank(buyer1);
        vm.expectRevert("Insufficient payment");
        factory.mintInscription{value: price - 0.001 ether}(tokenAddress);
    }
    
    function test_FeeDistribution() public {
        // 部署代币
        vm.prank(creator);
        address tokenAddress = factory.deployInscription(symbol, totalSupply, perMint, price);
        
        // 记录初始余额
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialCreatorBalance = creator.balance;
        
        // 铸造多次代币
        for(uint256 i = 0; i < 5; i++) {
            vm.prank(buyer1);
            factory.mintInscription{value: price}(tokenAddress);
        }
        
        // 计算应分配的费用
        uint256 totalPayment = price * 5;
        uint256 expectedOwnerFee = (totalPayment * 1) / 100; // 1%
        uint256 expectedCreatorFee = totalPayment - expectedOwnerFee; // 99%
        
        // 验证费用分配
        assertEq(owner.balance, initialOwnerBalance + expectedOwnerFee);
        assertEq(creator.balance, initialCreatorBalance + expectedCreatorFee);
    }
    
    function test_GetCreatorMemes() public {
        // 创建者部署多个Meme代币
        vm.startPrank(creator);
        
        address token1 = factory.deployInscription("PEPE", totalSupply, perMint, price);
        address token2 = factory.deployInscription("DOGE", totalSupply, perMint, price);
        address token3 = factory.deployInscription("SHIB", totalSupply, perMint, price);
        
        vm.stopPrank();
        
        // 获取创建者的所有Meme代币
        address[] memory creatorMemes = factory.getCreatorMemes(creator);
        
        // 验证数量和地址
        assertEq(creatorMemes.length, 3);
        assertEq(creatorMemes[0], token1);
        assertEq(creatorMemes[1], token2);
        assertEq(creatorMemes[2], token3);
    }
} 