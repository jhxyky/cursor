import { createPublicClient, http, parseAbiItem } from 'viem';
import { sepolia } from 'viem/chains';
import dotenv from 'dotenv';

dotenv.config();

// NFTMarket 合约的 ABI
const NFTMarketABI = [
    "event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, address token, uint256 price)",
    "event NFTPurchased(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, address seller, address token, uint256 price)",
    "event NFTUnlisted(address indexed nftContract, uint256 indexed tokenId, address indexed seller)"
];

async function main() {
    // 创建公共客户端
    const client = createPublicClient({
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL)
    });

    const nftMarketAddress = '0xCA50BAf6EAce43891d52124cC1c49E72b9b91991';

    console.log('正在启动 NFT 市场事件监听器...');
    console.log('合约地址:', nftMarketAddress);

    // 监听 NFT 上架事件
    const unwatchListed = client.watchEvent({
        address: nftMarketAddress,
        event: parseAbiItem('event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, address token, uint256 price)'),
        onLogs: (logs) => {
            console.log('\n收到 NFT 上架事件!');
            logs.forEach((log) => {
                console.log('事件详情:', {
                    nftContract: log.args.nftContract,
                    tokenId: log.args.tokenId?.toString(),
                    seller: log.args.seller,
                    token: log.args.token,
                    price: log.args.price ? Number(log.args.price) / 1e18 : '0',
                    blockNumber: log.blockNumber,
                    transactionHash: log.transactionHash
                });
            });
            console.log('-------------------');
        }
    });

    // 监听 NFT 购买事件
    const unwatchPurchased = client.watchEvent({
        address: nftMarketAddress,
        event: parseAbiItem('event NFTPurchased(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, address seller, address token, uint256 price)'),
        onLogs: (logs) => {
            console.log('\n收到 NFT 购买事件!');
            logs.forEach((log) => {
                console.log('事件详情:', {
                    nftContract: log.args.nftContract,
                    tokenId: log.args.tokenId?.toString(),
                    buyer: log.args.buyer,
                    seller: log.args.seller,
                    token: log.args.token,
                    price: log.args.price ? Number(log.args.price) / 1e18 : '0',
                    blockNumber: log.blockNumber,
                    transactionHash: log.transactionHash
                });
            });
            console.log('-------------------');
        }
    });

    // 监听 NFT 取消上架事件
    const unwatchUnlisted = client.watchEvent({
        address: nftMarketAddress,
        event: parseAbiItem('event NFTUnlisted(address indexed nftContract, uint256 indexed tokenId, address indexed seller)'),
        onLogs: (logs) => {
            console.log('\n收到 NFT 取消上架事件!');
            logs.forEach((log) => {
                console.log('事件详情:', {
                    nftContract: log.args.nftContract,
                    tokenId: log.args.tokenId?.toString(),
                    seller: log.args.seller,
                    blockNumber: log.blockNumber,
                    transactionHash: log.transactionHash
                });
            });
            console.log('-------------------');
        }
    });

    console.log('所有监听器已启动');

    // 处理程序退出
    const cleanup = () => {
        console.log('停止监听...');
        unwatchListed();
        unwatchPurchased();
        unwatchUnlisted();
    };

    // 处理进程退出
    process.on('SIGINT', () => {
        console.log('收到 SIGINT 信号，正在清理...');
        cleanup();
        process.exit(0);
    });

    process.on('SIGTERM', () => {
        console.log('收到 SIGTERM 信号，正在清理...');
        cleanup();
        process.exit(0);
    });
}

main().catch((error) => {
    console.error('监听器启动失败:', error);
    process.exit(1);
}); 