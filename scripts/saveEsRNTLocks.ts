import { createPublicClient, http, getAddress, formatEther, pad, keccak256 } from 'viem';
import { mainnet, sepolia } from 'viem/chains';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 创建本地链客户端
const client = createPublicClient({
  chain: {
    id: 31337,
    name: 'Anvil',
    network: 'localhost',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['http://localhost:8545'] },
      public: { http: ['http://localhost:8545'] }
    }
  },
  transport: http('http://localhost:8545')
});

// esRNT 合约地址
const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3' as `0x${string}`;

interface LockInfo {
  user: string;
  startTime: number;
  amount: string;
}

async function main() {
  console.log(`读取 esRNT 合约 (${CONTRACT_ADDRESS}) 中的 _locks 数组...`);

  try {
    // 读取数组长度，存储在 slot 0
    const lengthHex = await client.getStorageAt({
      address: CONTRACT_ADDRESS,
      slot: '0x0000000000000000000000000000000000000000000000000000000000000000'
    });
    
    // 将十六进制转换为数字
    const length = parseInt(lengthHex || '0x0', 16);
    console.log(`_locks 数组长度: ${length}`);
    
    // 计算数组存储的起始位置
    const baseSlot = keccak256(
      pad('0x0000000000000000000000000000000000000000000000000000000000000000', { size: 32 })
    );
    
    const locks: LockInfo[] = [];
    
    // 读取每个锁定信息
    for (let i = 0; i < length; i++) {
      const baseIndex = BigInt(i) * 3n;
      const currentSlot = (BigInt('0x' + baseSlot.slice(2)) + baseIndex).toString(16);
      
      // 读取 user 地址
      const userSlot = ('0x' + currentSlot.padStart(64, '0')) as `0x${string}`;
      const userHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: userSlot
      });
      const user = getAddress('0x' + (userHex || '0x0').slice(-40));
      
      // 读取 startTime
      const timeSlot = ('0x' + (BigInt('0x' + currentSlot) + 1n).toString(16).padStart(64, '0')) as `0x${string}`;
      const timeHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: timeSlot
      });
      const startTime = parseInt(timeHex || '0x0', 16);
      
      // 读取 amount
      const amountSlot = ('0x' + (BigInt('0x' + currentSlot) + 2n).toString(16).padStart(64, '0')) as `0x${string}`;
      const amountHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: amountSlot
      });
      const amount = formatEther(BigInt(amountHex || '0x0'));
      
      locks.push({
        user,
        startTime,
        amount
      });
      
      console.log(`已读取 locks[${i}]: user: ${user}, startTime: ${startTime} (${new Date(startTime * 1000).toLocaleString()}), amount: ${amount} ETH`);
    }

    // 创建 data 目录（如果不存在）
    const dataDir = path.join(__dirname, '..', 'data');
    await fs.mkdir(dataDir, { recursive: true });

    // 保存到 JSON 文件
    const outputPath = path.join(dataDir, 'esRNTLocks.json');
    await fs.writeFile(
      outputPath,
      JSON.stringify({
        contractAddress: CONTRACT_ADDRESS,
        lastUpdated: new Date().toISOString(),
        locks
      }, null, 2)
    );

    console.log(`\n数据已保存到: ${outputPath}`);
    
  } catch (error) {
    console.error('读取合约存储时出错:', error);
  }
}

main(); 