import { createPublicClient, http, parseAbiItem, type Log } from 'viem';
import { sepolia } from 'viem/chains';
import dotenv from 'dotenv';
import axios from 'axios';
import { createWalletClient } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

dotenv.config();

// JiaoToken 合约的 ABI
const JiaoTokenABI = [
    "event Transfer(address indexed from, address indexed to, uint256 value)"
];

// 保存事件数据到后端API
async function saveTransferToBackend(eventData: any) {
    try {
        // 将转账详情转换为文本
        const transferText = `从 ${eventData.from} 转账 ${parseFloat(eventData.value) / 1e18} 代币到 ${eventData.to}`;
        
        // 调用后端API
        const response = await axios.post('http://localhost:8080/api/saveEvenText', {
            address: eventData.from,
            text: transferText
        });
        
        console.log('转账记录已保存到后端:', response.data);
    } catch (error) {
        console.error('保存转账数据失败:', error);
    }
}

async function main() {
    // 创建公共客户端
    const client = createPublicClient({
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL || 'https://rpc.sepolia.org')
    });

    // 使用用户提供的合约地址
    const jiaoTokenAddress = '0xBC7281ab137A16a6772dE800aa2Dc3EFD61EE6aE'; // JiaoToken合约地址

    console.log('正在启动 JiaoToken 转账事件监听器...');
    console.log('合约地址:', jiaoTokenAddress);

    // 测试后端接口
    try {
        const testResponse = await axios.post('http://localhost:8080/api/saveEvenText', {
            address: '测试地址',
            text: '测试文本'
        });
        console.log('测试后端接口成功:', testResponse.data);
    } catch (error) {
        console.error('测试后端接口失败，可能需要确保后端服务已启动');
    }

    // 监听 Transfer 事件
    const unwatchTransfer = client.watchEvent({
        address: jiaoTokenAddress,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        onLogs: (logs) => {
            console.log('\n收到 Token 转账事件!');
            logs.forEach((log) => {
                const eventData = {
                    from: log.args.from,
                    to: log.args.to,
                    value: log.args.value ? log.args.value.toString() : '0',
                    blockNumber: log.blockNumber,
                    transactionHash: log.transactionHash,
                    timestamp: new Date().toISOString()
                };
                console.log('转账详情:', eventData);
                saveTransferToBackend(eventData);
            });
            console.log('-------------------');
        }
    });

    // 历史转账事件扫描
    async function scanHistoricalTransfers(fromBlock: bigint, toBlock: bigint) {
        console.log(`扫描历史转账，从区块 ${fromBlock} 到 ${toBlock}`);
        
        try {
            const logs = await client.getLogs({
                address: jiaoTokenAddress,
                event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
                fromBlock,
                toBlock
            });
            
            console.log(`找到 ${logs.length} 个历史转账事件`);
            
            for (const log of logs) {
                const eventData = {
                    from: log.args.from,
                    to: log.args.to,
                    value: log.args.value ? log.args.value.toString() : '0',
                    blockNumber: log.blockNumber,
                    transactionHash: log.transactionHash,
                    timestamp: new Date().toISOString() // 注意：这里使用当前时间，理想情况下应该获取区块的时间戳
                };
                await saveTransferToBackend(eventData);
            }
            
            console.log('历史转账事件处理完成');
        } catch (error) {
            console.error('扫描历史转账失败:', error);
        }
    }

    // 获取当前区块
    const currentBlock = await client.getBlockNumber();
    // 扫描最近1000个区块的历史转账
    const fromBlock = currentBlock - BigInt(1000) > 0 ? currentBlock - BigInt(1000) : BigInt(0);
    await scanHistoricalTransfers(fromBlock, currentBlock);

    console.log('转账监听器已成功启动，现在可以通过前端进行转账');

    // 处理程序退出
    const cleanup = () => {
        console.log('停止监听...');
        unwatchTransfer();
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