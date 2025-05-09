import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

// NFTMarket 合约的 ABI
const NFTMarketABI = [
    "function listNFT(address nftContract, uint256 tokenId, address token, uint256 price) external",
    "function getListing(address nftContract, uint256 tokenId) external view returns (address seller, address token, uint256 price, bool isActive)"
];

// ERC721 合约的 ABI
const ERC721ABI = [
    "function approve(address to, uint256 tokenId) external",
    "function ownerOf(uint256 tokenId) external view returns (address)"
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
    const nftContractAddress = "0xD451d14F89F5aA4C8e9B345F2a8D8904b94F7198"; // 新部署的 NFT 合约地址
    const tokenId = 0; // 要上架的 NFT 的 tokenId
    const price = ethers.parseEther("0.1"); // 价格设置为 0.1 ETH
    const paymentToken = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"; // WETH 代币地址

    try {
        // 获取 NFT 合约实例
        const nftContract = new ethers.Contract(nftContractAddress, ERC721ABI, wallet);
        
        // 检查 NFT 所有权
        const owner = await nftContract.ownerOf(tokenId);
        console.log("NFT 所有者:", owner);
        console.log("当前钱包地址:", wallet.address);
        
        if (owner.toLowerCase() !== wallet.address.toLowerCase()) {
            throw new Error("您不是这个 NFT 的所有者");
        }

        // 批准 NFTMarket 合约转移 NFT
        console.log("正在批准 NFTMarket 合约转移 NFT...");
        const approveTx = await nftContract.approve(nftMarket.target, tokenId);
        await approveTx.wait();
        console.log("NFT 转移已批准");

        // 上架 NFT
        console.log("正在上架 NFT...");
        const tx = await nftMarket.listNFT(nftContractAddress, tokenId, paymentToken, price);
        console.log("交易已发送，等待确认...");
        await tx.wait();
        console.log("NFT 上架成功！");
        console.log("交易哈希:", tx.hash);

        // 验证上架状态
        const listing = await nftMarket.getListing(nftContractAddress, tokenId);
        console.log("上架信息:", {
            seller: listing[0],
            token: listing[1],
            price: ethers.formatEther(listing[2]),
            isActive: listing[3]
        });
    } catch (error) {
        console.error("上架 NFT 时出错:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 