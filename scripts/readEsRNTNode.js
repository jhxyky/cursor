import { createPublicClient, http, getAddress, formatEther, pad, keccak256 } from 'viem';
import { createLocal } from 'viem/chains';

// 创建本地链客户端
const client = createPublicClient({
  chain: createLocal({ 
    id: 31337, 
    name: 'Anvil', 
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 } 
  }),
  transport: http('http://localhost:8545')
});

// esRNT 合约地址
const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

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
    // 在 Solidity 中，动态数组的存储位置是 keccak256(slot)
    const baseSlot = keccak256(
      pad('0x0000000000000000000000000000000000000000000000000000000000000000', { size: 32 })
    );
    
    // 读取每个锁定信息
    for (let i = 0; i < length; i++) {
      // 每个结构体占用 3 个槽位
      // user: 第一个槽位
      // startTime: 第二个槽位
      // amount: 第三个槽位
      
      const baseIndex = BigInt(i) * 3n; // 每个元素占 3 个槽
      const currentSlot = (BigInt('0x' + baseSlot.slice(2)) + baseIndex).toString(16);
      
      // 读取 user 地址
      const userSlot = '0x' + currentSlot.padStart(64, '0');
      const userHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: userSlot
      });
      const user = getAddress('0x' + (userHex || '0x0').slice(-40));
      
      // 读取 startTime
      const timeSlot = '0x' + (BigInt('0x' + currentSlot) + 1n).toString(16).padStart(64, '0');
      const timeHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: timeSlot
      });
      const startTime = parseInt(timeHex || '0x0', 16);
      
      // 读取 amount
      const amountSlot = '0x' + (BigInt('0x' + currentSlot) + 2n).toString(16).padStart(64, '0');
      const amountHex = await client.getStorageAt({
        address: CONTRACT_ADDRESS,
        slot: amountSlot
      });
      const amount = formatEther(BigInt(amountHex || '0x0'));
      
      console.log(`locks[${i}]: user: ${user}, startTime: ${startTime} (${new Date(startTime * 1000).toLocaleString()}), amount: ${amount} ETH`);
    }
  } catch (error) {
    console.error('读取合约存储时出错:', error);
  }
}

main(); 