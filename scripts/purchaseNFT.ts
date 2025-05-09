import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

// NFTMarket 合约的 ABI
const NFTMarketABI = [
    "function purchaseNFT(address nftContract, uint256 tokenId) external",
    "function getListing(address nftContract, uint256 tokenId) external view returns (address seller, address token, uint256 price, bool isActive)"
];

// ERC20 合约的 ABI
const ERC20ABI = [
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function balanceOf(address account) external view returns (uint256)"
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
    const tokenId = 0; // 要购买的 NFT 的 tokenId
    const wethAddress = "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"; // WETH 代币地址

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

        if (listing[0].toLowerCase() === wallet.address.toLowerCase()) {
            throw new Error("不能购买自己的 NFT");
        }

        // 获取 WETH 合约实例
        const wethContract = new ethers.Contract(wethAddress, ERC20ABI, wallet);
        
        // 检查 WETH 余额
        const balance = await wethContract.balanceOf(wallet.address);
        console.log("当前 WETH 余额:", ethers.formatEther(balance));
        
        if (balance < listing[2]) {
            throw new Error("WETH 余额不足");
        }

        // 批准 NFTMarket 合约使用 WETH
        console.log("正在批准 NFTMarket 合约使用 WETH...");
        const approveTx = await wethContract.approve(nftMarket.target, listing[2]);
        await approveTx.wait();
        console.log("WETH 使用已批准");

        // 购买 NFT
        console.log("正在购买 NFT...");
        const tx = await nftMarket.purchaseNFT(nftContractAddress, tokenId);
        console.log("交易已发送，等待确认...");
        await tx.wait();
        console.log("NFT 购买成功！");
        console.log("交易哈希:", tx.hash);

    } catch (error) {
        console.error("购买 NFT 时出错:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 