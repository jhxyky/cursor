import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

// ERC721 合约的 ABI
const ERC721ABI = [
    "function safeTransferFrom(address from, address to, uint256 tokenId) external",
    "function ownerOf(uint256 tokenId) external view returns (address)"
];

async function main() {
    // 连接到 Sepolia 网络
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
    
    // NFT 合约地址
    const nftContractAddress = "0x9d1b68DaC8cD2df38C05076B8f9fd476D401D3dC";
    const tokenId = 0;
    
    // 目标地址（当前钱包地址）
    const toAddress = "0x353a4F1a2bD8Ed73305dfB8FBD998271465bf367";

    try {
        // 获取 NFT 合约实例
        const nftContract = new ethers.Contract(nftContractAddress, ERC721ABI, wallet);
        
        // 检查 NFT 所有权
        const owner = await nftContract.ownerOf(tokenId);
        console.log("NFT 当前所有者:", owner);
        console.log("当前钱包地址:", wallet.address);
        
        if (owner.toLowerCase() !== wallet.address.toLowerCase()) {
            throw new Error("您不是这个 NFT 的所有者");
        }

        // 转移 NFT
        console.log("正在转移 NFT...");
        const tx = await nftContract.safeTransferFrom(wallet.address, toAddress, tokenId);
        console.log("交易已发送，等待确认...");
        await tx.wait();
        console.log("NFT 转移成功！");
        console.log("交易哈希:", tx.hash);

        // 验证转移结果
        const newOwner = await nftContract.ownerOf(tokenId);
        console.log("NFT 新所有者:", newOwner);
    } catch (error) {
        console.error("转移 NFT 时出错:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 