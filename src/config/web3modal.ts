import { createWeb3Modal } from '@web3modal/wagmi/react'
import { defaultWagmiConfig } from '@web3modal/wagmi/react/config'
import { sepolia } from 'wagmi/chains'

// 1. 定义支持的链
const chains = [sepolia]

// 2. 创建wagmi配置
export function createWeb3ModalConfig() {
  const wagmiConfig = defaultWagmiConfig({
    chains,
    projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || '',
    metadata: {
      name: 'NFT Marketplace',
      description: 'NFT交易市场应用',
      icons: ['https://avatars.githubusercontent.com/u/37784886'],
      url: 'https://nft-marketplace.example.com' 
    }
  })

  // 3. 创建modal
  createWeb3Modal({
    wagmiConfig,
    projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || '',
    chains,
    themeVariables: {
      '--w3m-accent': '#3b82f6' // Tailwind蓝色
    }
  })

  return wagmiConfig
} 