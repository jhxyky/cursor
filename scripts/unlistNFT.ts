import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

// NFTMarket 合约的 ABI
const NFTMarketABI = [
    "function unlistNFT(address nftContract, uint256 tokenId) external",
    "function getListing(address nftContract, uint256 tokenId) external view returns (address seller, address token, uint256 price, bool isActive)"
];

async function main() {
    // 连接到 Sepolia 网络
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
    
    // 获取合约实例
    const nftMarket = new ethers.Contract(
        "0xCA50BAf6EAce43891d52124cC1c49E72b9b91991", // NFTMarket 合约地址
        NFTMarketABI,
        wallet
    );

    // 设置 NFT 合约地址和代币 ID
    const nftContractAddress = "0xD451d14F89F5aA4C8e9B345F2a8D8904b94F7198"; // NFT 合约地址
    const tokenId = 0; // 要取消上架的 NFT 的 tokenId

    try {
        // 获取上架信息
        const listing = await nftMarket.getListing(nftContractAddress, tokenId);
        console.log("NFT 上架信息:", {
            seller: listing[0],
            token: listing[1],
            price: ethers.formatEther(listing[2]),
            isActive: listing[3]
        });

        if (!listing[3]) {
            throw new Error("NFT 未上架");
        }

        if (listing[0].toLowerCase() !== wallet.address.toLowerCase()) {
            throw new Error("您不是这个 NFT 的卖家");
        }

        // 取消上架 NFT
        console.log("正在取消上架 NFT...");
        const tx = await nftMarket.unlistNFT(nftContractAddress, tokenId);
        console.log("交易已发送，等待确认...");
        await tx.wait();
        console.log("NFT 取消上架成功！");
        console.log("交易哈希:", tx.hash);

        // 验证上架状态
        const newListing = await nftMarket.getListing(nftContractAddress, tokenId);
        console.log("更新后的上架信息:", {
            seller: newListing[0],
            token: newListing[1],
            price: ethers.formatEther(newListing[2]),
            isActive: newListing[3]
        });
    } catch (error) {
        console.error("取消上架 NFT 时出错:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 