// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/JiaoToken.sol";
import "../src/TokenBank.sol";
import "../src/JiaoNFT.sol";
import "../src/JiaoNFTMarket.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TokenPermitTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    JiaoToken public token;
    TokenBank public bank;
    JiaoNFT public nft;
    JiaoNFTMarket public market;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    uint256 public whitelistSignerPrivateKey = 0xA11CE;
    address public whitelistSigner;

    // 部署合约并初始化测试环境
    function setUp() public {
        vm.startPrank(owner);
        
        // 计算白名单签名者地址
        whitelistSigner = vm.addr(whitelistSignerPrivateKey);
        
        // 部署合约
        token = new JiaoToken();
        bank = new TokenBank(address(token));
        nft = new JiaoNFT();
        market = new JiaoNFTMarket(whitelistSigner);
        
        // 为测试用户分配代币
        token.mint(user1, 1000 * 10**18);
        token.mint(user2, 1000 * 10**18);
        
        // 为测试用户铸造NFT
        nft.mint(owner); // tokenId 0
        nft.mint(owner); // tokenId 1
        
        vm.stopPrank();
    }

    // 测试使用permit进行代币授权存款
    function testPermitDeposit() public {
        // 准备测试数据
        uint256 privateKey = 0xB0B;
        address user = vm.addr(privateKey);
        uint256 amount = 100 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 给用户发送代币
        vm.prank(owner);
        token.mint(user, amount);
        
        // 获取链ID
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        
        // 计算permit签名
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        user,
                        address(bank),
                        amount,
                        token.nonces(user),
                        deadline
                    )
                )
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, permitHash);
        
        // 执行permit存款
        vm.prank(user);
        bank.permitDeposit(amount, deadline, v, r, s);
        
        // 验证存款结果
        assertEq(bank.balanceOf(user), amount);
        assertEq(token.balanceOf(address(bank)), amount);
        
        // 输出日志，显示存款结果
        console.log("User Address:", user);
        console.log("Deposit Amount:", amount / 1e18, "JIAO");
        console.log("Bank Contract Balance:", token.balanceOf(address(bank)) / 1e18, "JIAO");
    }
    
    // 测试白名单授权购买NFT
    function testPermitBuyNFT() public {
        uint256 tokenId = 0;  // 第一个铸造的NFT
        uint256 price = 50 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;

        // 准备NFT上架
        vm.startPrank(owner);
        nft.approve(address(market), tokenId);
        market.listNFT(address(nft), tokenId, address(token), price);
        vm.stopPrank();
        
        // 获取NFT所有者和buyer的初始代币余额
        address originalOwner = owner;
        uint256 ownerInitialBalance = token.balanceOf(originalOwner);
        uint256 buyerInitialBalance = token.balanceOf(user1);
        
        // user1获取白名单签名
        bytes32 messageHash = keccak256(abi.encodePacked(
            user1,
            address(nft),
            tokenId,
            deadline
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(whitelistSignerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // user1批准代币转账并购买NFT
        vm.startPrank(user1);
        token.approve(address(market), price);
        market.permitBuy(address(nft), tokenId, deadline, signature);
        vm.stopPrank();
        
        // 验证购买结果
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(token.balanceOf(user1), buyerInitialBalance - price);
        assertEq(token.balanceOf(originalOwner), ownerInitialBalance + price);
        
        // 输出日志，显示NFT转移和代币转移
        console.log("NFT ID:", tokenId);
        console.log("NFT New Owner:", user1);
        console.log("Seller Address:", originalOwner);
        console.log("NFT Price:", price / 1e18, "JIAO");
        console.log("Buyer Balance Change:", (buyerInitialBalance - token.balanceOf(user1)) / 1e18, "JIAO");
        console.log("Seller Balance Change:", (token.balanceOf(originalOwner) - ownerInitialBalance) / 1e18, "JIAO");
    }
    
    // 测试非白名单用户无法购买NFT
    function testRevert_NonWhitelistBuy() public {
        uint256 tokenId = 1; // 第二个铸造的NFT
        uint256 price = 50 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 准备NFT上架
        vm.startPrank(owner);
        nft.approve(address(market), tokenId);
        market.listNFT(address(nft), tokenId, address(token), price);
        vm.stopPrank();
        
        // 伪造签名(使用错误的私钥)
        uint256 fakePrivateKey = 0xD3AD;
        bytes32 messageHash = keccak256(abi.encodePacked(
            user2,
            address(nft),
            tokenId,
            deadline
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakePrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // user2尝试购买NFT，预期会失败
        vm.startPrank(user2);
        token.approve(address(market), price);
        
        // 预期会抛出错误："Invalid signature"
        vm.expectRevert("Invalid signature");
        market.permitBuy(address(nft), tokenId, deadline, signature);
        vm.stopPrank();
    }
} 