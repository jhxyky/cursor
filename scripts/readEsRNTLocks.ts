import { createPublicClient, http, parseAbi, getAddress, formatEther } from 'viem';
import { mainnet, sepolia } from 'viem/chains';
import { keccak256, toHex, encodePacked, pad } from 'viem';
import { Command } from 'commander';

// 创建命令行解析器
const program = new Command();

program
  .name('read-esrnt-locks')
  .description('从链上读取 esRNT 合约的 _locks 数组')
  .option('-a, --address <string>', '合约地址')
  .option('-r, --rpc <string>', 'RPC URL', 'https://rpc.sepolia.org')
  .option('-c, --chain <string>', '链名称 (sepolia 或 mainnet)', 'sepolia')
  .parse(process.argv);

const options = program.opts();

// 合约地址验证
if (!options.address) {
  console.error('错误: 必须提供合约地址 (-a 或 --address)');
  process.exit(1);
}

// 选择链
const chain = options.chain === 'mainnet' ? mainnet : sepolia;

// 创建客户端
const client = createPublicClient({
  chain,
  transport: http(options.rpc)
});

const CONTRACT_ADDRESS = options.address;

async function main() {
  console.log(`读取 ${chain.name} 链上的 esRNT 合约 (${CONTRACT_ADDRESS}) 中的 _locks 数组...`);

  try {
    // 读取数组长度，存储在 slot 0
    const lengthHex = await client.getStorageAt({
      address: CONTRACT_ADDRESS as `0x${string}`,
      slot: '0x0000000000000000000000000000000000000000000000000000000000000000'
    });
    
    // 将十六进制转换为数字
    const length = parseInt(lengthHex || '0x0', 16);
    console.log(`_locks 数组长度: ${length}`);
    
    // 计算数组存储的起始位置
    // 在 Solidity 中，动态数组的存储位置是 keccak256(slot)
    const baseSlot = keccak256(
      pad('0x0000000000000000000000000000000000000000000000000000000000000000', { size: 32 })
    );
    
    // 读取每个锁定信息
    for (let i = 0; i < length; i++) {
      // 计算当前元素的存储位置
      // 每个 LockInfo 结构占用 3 个槽位
      // user: 第一个槽位 (32 bytes)
      // startTime: 第二个槽位 (8 bytes)
      // amount: 第三个槽位 (32 bytes)
      
      const baseIndex = BigInt(i) * 3n; // 每个元素占 3 个槽
      const currentSlot = (BigInt('0x' + baseSlot.slice(2)) + baseIndex).toString(16);
      
      // 读取 user 地址 (slot + 0)
      const userSlot = '0x' + currentSlot.padStart(64, '0');
      const userHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS as `0x${string}`,
        slot: userSlot as `0x${string}`
      });
      const user = getAddress('0x' + (userHex || '0x0').slice(-40));
      
      // 读取 startTime (slot + 1)
      const timeSlot = '0x' + (BigInt('0x' + currentSlot) + 1n).toString(16).padStart(64, '0');
      const timeHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS as `0x${string}`,
        slot: timeSlot as `0x${string}`
      });
      const startTime = parseInt(timeHex || '0x0', 16);
      
      // 读取 amount (slot + 2)
      const amountSlot = '0x' + (BigInt('0x' + currentSlot) + 2n).toString(16).padStart(64, '0');
      const amountHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS as `0x${string}`,
        slot: amountSlot as `0x${string}`
      });
      const amount = formatEther(BigInt(amountHex || '0x0'));
      
      console.log(`locks[${i}]: user: ${user}, startTime: ${startTime} (${new Date(startTime * 1000).toLocaleString()}), amount: ${amount} ETH`);
    }
  } catch (error) {
    console.error('读取合约存储时出错:', error);
  }
}

main().catch(console.error); 