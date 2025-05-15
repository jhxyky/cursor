import { createWeb3Modal } from '@web3modal/wagmi/react'
import { defaultWagmiConfig } from '@web3modal/wagmi/react/config'
import { sepolia } from 'wagmi/chains'

// 1. 定义支持的链
const chains = [sepolia] as const

// 从环境变量获取Project ID (使用@ts-ignore解决类型问题)
// @ts-ignore - vite环境变量类型问题
const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || 'e1b9829879ab6230b4bd97d4135e0a01'

// 检测是否支持Web3
const isWeb3Supported = () => {
  // @ts-ignore - window.ethereum类型问题
  return typeof window !== 'undefined' && window.ethereum ? '是' : '否';
}

// 2. 创建wagmi配置
export function createWeb3ModalConfig() {
  console.log('创建Web3Modal配置，ProjectID:', projectId);
  console.log('当前使用的链:', chains[0].name);
  
  try {
    // 打印环境信息
    console.log('执行环境:', typeof window !== 'undefined' ? '浏览器' : 'Node.js');
    console.log('是否支持Web3:', isWeb3Supported());
    
    // wagmi v2配置
    const wagmiConfig = defaultWagmiConfig({
      chains,
      projectId,
      metadata: {
        name: 'NFT Marketplace',
        description: 'NFT交易市场应用',
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
        url: 'https://nft-marketplace.example.com' 
      }
    })

    // 3. 创建modal
    console.log('初始化Web3Modal...');
    // @ts-ignore - 类型错误
    const modal = createWeb3Modal({
      wagmiConfig,
      projectId,
      themeMode: 'light',
      themeVariables: {
        '--w3m-accent': '#3b82f6' // Tailwind蓝色
      },
      // 禁用分析服务，解决网络问题
      enableAnalytics: false
    })

    // 调试信息
    console.log('Web3Modal初始化成功');
    console.log('W3M对象可用:', !!modal);
    
    return wagmiConfig;
  } catch (error) {
    console.error('初始化Web3Modal时出错:', error);
    // 显示警告
    if (typeof window !== 'undefined') {
      alert('初始化Web3Modal失败: ' + String(error));
    }
    throw error;
  }
} 