// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/MerkleNFT.sol";
import "../contracts/MerkleToken.sol";
import "../contracts/AirdropMerkleNFTMarket.sol";
import "../contracts/Multicall.sol";
import "../contracts/MerkleProofHelper.sol";

/**
 * @title AirdropMerkleNFTMarketTest
 * @dev NFT 市场合约的测试合约
 * 测试白名单验证、NFT 购买、折扣计算等功能
 */
contract AirdropMerkleNFTMarketTest is Test {
    // 合约实例
    MerkleNFT public nft;            // NFT 合约
    MerkleToken public token;        // 代币合约
    AirdropMerkleNFTMarket public market;  // 市场合约
    Multicall public multicall;      // 多调用合约
    
    // 测试账户
    address public owner;            // 合约拥有者
    address public user1;            // 白名单用户 1
    address public user2;            // 白名单用户 2
    bytes32 public merkleRoot;       // Merkle 树根节点
    bytes32[] public leaves;         // Merkle 树叶子节点数组
    
    /**
     * @dev 测试初始化函数
     * 设置测试环境，部署合约，构建白名单
     */
    function setUp() public {
        // 设置测试账户
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 切换到 owner 账户
        vm.startPrank(owner);
        
        // 部署合约
        nft = new MerkleNFT();
        token = new MerkleToken("MerkleToken", "MTK", 1000000);
        
        // 构建白名单 Merkle 树
        leaves = new bytes32[](2);
        leaves[0] = MerkleProofHelper.getLeaf(user1);
        leaves[1] = MerkleProofHelper.getLeaf(user2);
        
        // 计算 Merkle 根
        merkleRoot = calculateRoot(leaves);
        
        // 部署市场合约
        market = new AirdropMerkleNFTMarket(
            address(nft),
            address(token),
            merkleRoot
        );
        
        // 部署 Multicall 合约
        multicall = new Multicall();
        
        // 铸造 NFT 并转移到市场
        nft.mint(address(market));
        nft.mint(address(market));
        
        // 上架 NFT
        market.listNFT(1, 1 ether);
        market.listNFT(2, 2 ether);
        
        // 给用户铸造代币
        token.mint(user1, 10 ether);
        token.mint(user2, 10 ether);
        
        vm.stopPrank();
    }
    
    /**
     * @dev 计算 Merkle 树根节点
     * @param _leaves 叶子节点数组
     * @return bytes32 根节点哈希值
     * 
     * 使用递归方式计算 Merkle 树的根节点
     * 对相邻的叶子节点进行排序和哈希，直到得到根节点
     */
    function calculateRoot(bytes32[] memory _leaves) internal pure returns (bytes32) {
        require(_leaves.length > 0, "Empty leaves");
        
        if (_leaves.length == 1) {
            return _leaves[0];
        }
        
        bytes32[] memory nextLevel = new bytes32[](_leaves.length / 2 + (_leaves.length % 2));
        
        for (uint i = 0; i < _leaves.length; i += 2) {
            if (i + 1 < _leaves.length) {
                nextLevel[i/2] = keccak256(abi.encodePacked(
                    _leaves[i] < _leaves[i+1] ? _leaves[i] : _leaves[i+1],
                    _leaves[i] < _leaves[i+1] ? _leaves[i+1] : _leaves[i]
                ));
            } else {
                nextLevel[i/2] = _leaves[i];
            }
        }
        
        return calculateRoot(nextLevel);
    }
    
    /**
     * @dev 获取账户的 Merkle 证明
     * @param account 要验证的账户地址
     * @return bytes32[] Merkle 证明路径
     * 
     * 根据账户地址生成 Merkle 证明
     * 找到对应的叶子节点，然后获取其兄弟节点作为证明
     */
    function getProof(address account) internal view returns (bytes32[] memory) {
        bytes32 leaf = MerkleProofHelper.getLeaf(account);
        uint256 leafIndex;
        
        // 查找叶子节点的索引
        for (uint256 i = 0; i < leaves.length; i++) {
            if (leaves[i] == leaf) {
                leafIndex = i;
                break;
            }
        }
        
        // 生成证明路径
        bytes32[] memory proof = new bytes32[](1);
        if (leafIndex % 2 == 0) {
            if (leafIndex + 1 < leaves.length) {
                proof[0] = leaves[leafIndex + 1];
            } else {
                proof[0] = leaves[leafIndex];
            }
        } else {
            proof[0] = leaves[leafIndex - 1];
        }
        
        return proof;
    }
    
    /**
     * @dev 测试白名单验证功能
     * 验证白名单用户是否能通过 Merkle 树验证
     */
    function testWhitelistVerification() public {
        bytes32[] memory proof = getProof(user1);
        assertTrue(market.isWhitelisted(user1, proof));
        
        proof = getProof(user2);
        assertTrue(market.isWhitelisted(user2, proof));
    }
    
    /**
     * @dev 测试带折扣的 NFT 购买功能
     * 验证白名单用户是否能以折扣价购买 NFT
     */
    function testClaimNFTWithDiscount() public {
        bytes32[] memory proof = getProof(user1);
        
        vm.startPrank(user1);
        
        // 授权代币
        token.approve(address(market), 1 ether);
        
        // 领取 NFT
        market.claimNFT(1, proof);
        
        // 验证 NFT 所有权
        assertEq(nft.ownerOf(1), user1);
        
        // 验证已购买记录
        assertTrue(market.hasClaimed(user1, 1));
        
        vm.stopPrank();
    }
    
    /**
     * @dev 测试非白名单用户购买限制
     * 验证非白名单用户是否会被正确拒绝
     */
    function testNonWhitelistedUserCannotClaim() public {
        address nonWhitelistedUser = makeAddr("nonWhitelisted");
        bytes32[] memory proof = getProof(user1); // 使用其他用户的证明
        
        vm.startPrank(nonWhitelistedUser);
        
        vm.expectRevert("Not whitelisted");
        market.claimNFT(1, proof);
        
        vm.stopPrank();
    }
    
    /**
     * @dev 测试重复购买限制
     * 验证用户是否能重复购买同一个 NFT
     */
    function testCannotDoubleClaim() public {
        bytes32[] memory proof = getProof(user1);
        
        vm.startPrank(user1);
        
        // 第一次领取
        token.approve(address(market), 1 ether);
        market.claimNFT(1, proof);
        
        // 尝试第二次领取
        vm.expectRevert("Already claimed");
        market.claimNFT(1, proof);
        
        vm.stopPrank();
    }
    
    /**
     * @dev 测试折扣计算功能
     * 验证折扣计算是否正确
     */
    function testDiscountCalculation() public {
        uint256 originalPrice = 1 ether;
        uint256 discountedPrice = market.getDiscountedPrice(originalPrice);
        
        assertEq(discountedPrice, originalPrice / 2);
    }
} 