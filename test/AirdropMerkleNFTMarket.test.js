const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

describe("AirdropMerkleNFTMarket", function () {
    let merkleNFT;
    let merkleToken;
    let market;
    let owner;
    let user1;
    let user2;
    let merkleTree;
    let merkleRoot;
    let whitelist;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        // 部署 NFT 合约
        const MerkleNFT = await ethers.getContractFactory("MerkleNFT");
        merkleNFT = await MerkleNFT.deploy();

        // 部署 Token 合约
        const MerkleToken = await ethers.getContractFactory("MerkleToken");
        merkleToken = await MerkleToken.deploy("MerkleToken", "MTK", 1000000);

        // 构建白名单
        whitelist = [user1.address, user2.address];
        const leaves = whitelist.map(addr => keccak256(addr));
        merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
        merkleRoot = merkleTree.getHexRoot();

        // 部署市场合约
        const AirdropMerkleNFTMarket = await ethers.getContractFactory("AirdropMerkleNFTMarket");
        market = await AirdropMerkleNFTMarket.deploy(
            merkleNFT.address,
            merkleToken.address,
            merkleRoot
        );

        // 铸造 NFT 并转移到市场
        await merkleNFT.mint(market.address);
        await merkleNFT.mint(market.address);

        // 上架 NFT
        await market.listNFT(1, ethers.parseEther("1"));
        await market.listNFT(2, ethers.parseEther("2"));

        // 给用户铸造代币
        await merkleToken.mint(user1.address, ethers.parseEther("10"));
        await merkleToken.mint(user2.address, ethers.parseEther("10"));
    });

    it("should verify whitelist correctly", async function () {
        const proof = merkleTree.getHexProof(keccak256(user1.address));
        expect(await market.isWhitelisted(user1.address, proof)).to.be.true;
    });

    it("should allow whitelisted user to claim NFT with discount", async function () {
        const proof = merkleTree.getHexProof(keccak256(user1.address));
        
        // 授权代币
        await merkleToken.connect(user1).approve(market.address, ethers.parseEther("1"));
        
        // 领取 NFT
        await market.connect(user1).claimNFT(1, proof);
        
        // 验证 NFT 所有权
        expect(await merkleNFT.ownerOf(1)).to.equal(user1.address);
        
        // 验证已购买记录
        expect(await market.hasClaimed(user1.address, 1)).to.be.true;
    });

    it("should not allow non-whitelisted user to claim NFT", async function () {
        const nonWhitelistedUser = ethers.Wallet.createRandom();
        const proof = merkleTree.getHexProof(keccak256(nonWhitelistedUser.address));
        
        await expect(
            market.connect(nonWhitelistedUser).claimNFT(1, proof)
        ).to.be.revertedWith("Not whitelisted");
    });

    it("should not allow double claiming", async function () {
        const proof = merkleTree.getHexProof(keccak256(user1.address));
        
        // 第一次领取
        await merkleToken.connect(user1).approve(market.address, ethers.parseEther("1"));
        await market.connect(user1).claimNFT(1, proof);
        
        // 尝试第二次领取
        await expect(
            market.connect(user1).claimNFT(1, proof)
        ).to.be.revertedWith("Already claimed");
    });

    it("should apply 50% discount", async function () {
        const proof = merkleTree.getHexProof(keccak256(user1.address));
        const originalPrice = ethers.parseEther("1");
        const discountedPrice = await market.getDiscountedPrice(originalPrice);
        
        expect(discountedPrice).to.equal(originalPrice.div(2));
    });
}); 