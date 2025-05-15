import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { createWeb3ModalConfig } from './config/web3modal.ts';

// 添加调试日志
console.log('初始化应用...');

// 尝试从.env获取WalletConnect项目ID
// @ts-ignore - vite环境变量类型问题
const walletConnectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;
console.log('环境变量VITE_WALLETCONNECT_PROJECT_ID:', walletConnectId ? '已设置' : '未设置');

// 创建React Query客户端
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5分钟
      refetchOnWindowFocus: false,
    },
  },
});

// 使用web3modal配置
try {
  console.log('创建Web3Modal配置...');
  const wagmiConfig = createWeb3ModalConfig();
  console.log('Web3Modal配置创建成功');

  // 渲染应用
  const rootElement = document.getElementById('root');
  if (rootElement) {
    ReactDOM.createRoot(rootElement).render(
      <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
      </WagmiProvider>,
    );
    console.log('应用已渲染');
  } else {
    console.error('找不到root元素，应用无法渲染');
  }
} catch (error) {
  console.error('初始化应用时发生错误:', error);
  // 显示友好的错误信息
  const rootElement = document.getElementById('root');
  if (rootElement) {
    ReactDOM.createRoot(rootElement).render(
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md max-w-md w-full">
          <h2 className="text-red-500 text-xl font-bold mb-4">应用初始化失败</h2>
          <p className="text-gray-700 mb-4">
            Web3连接配置出现问题，请刷新页面或检查控制台获取更多信息。
          </p>
          <button 
            onClick={() => window.location.reload()}
            className="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            刷新页面
          </button>
        </div>
      </div>
    );
  }
} 