import React, { useState, lazy, Suspense } from 'react';
import ConnectWallet from './components/ConnectWallet';
import SIWEAuth from './components/SIWEAuth';
// 使用懒加载延迟加载非核心组件
const TokenBankFrontend = lazy(() => import('./components/TokenBankFrontend'));
const NFTMarketplace = lazy(() => import('./components/NFTMarketplace'));
const TokenTransferHistory = lazy(() => import('./components/TokenTransferHistory'));
import { useAccount } from 'wagmi';

// 简单的加载组件
const LoadingComponent = () => (
  <div className="flex justify-center items-center p-8">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
    <p className="ml-3">加载中...</p>
  </div>
);

// 错误边界组件
class ErrorBoundary extends React.Component<{children: React.ReactNode}, {hasError: boolean}> {
  constructor(props: {children: React.ReactNode}) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="text-center p-4 bg-red-50 text-red-500 rounded">
          <p>组件加载失败，请刷新页面重试</p>
        </div>
      );
    }

    return this.props.children;
  }
}

function App() {
  const { isConnected } = useAccount();
  const [activeTab, setActiveTab] = useState<'nft' | 'token' | 'transfers'>('nft');

  return (
    <div className="min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12">
      <div className="relative py-3 sm:max-w-4xl sm:mx-auto">
        <div className="relative px-4 py-10 bg-white shadow-lg sm:rounded-3xl sm:p-20">
          <div className="mx-auto">
            <div className="mb-6 flex justify-between items-center">
              <h1 className="text-2xl font-bold text-gray-900">NFT市场应用</h1>
              <div className="mt-4 flex space-x-4">
                <ConnectWallet />
                <SIWEAuth />
              </div>
            </div>
            
            {isConnected && (
              <div className="mb-6">
                <div className="border-b border-gray-200">
                  <nav className="-mb-px flex">
                    <button
                      onClick={() => setActiveTab('nft')}
                      className={`py-2 px-4 text-center border-b-2 ${
                        activeTab === 'nft' 
                          ? 'border-indigo-500 text-indigo-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      NFT市场
                    </button>
                    <button
                      onClick={() => setActiveTab('token')}
                      className={`py-2 px-4 text-center border-b-2 ${
                        activeTab === 'token' 
                          ? 'border-indigo-500 text-indigo-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      代币银行
                    </button>
                    <button
                      onClick={() => setActiveTab('transfers')}
                      className={`py-2 px-4 text-center border-b-2 ${
                        activeTab === 'transfers' 
                          ? 'border-indigo-500 text-indigo-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      转账记录
                    </button>
                  </nav>
                </div>
              </div>
            )}
            
            <ErrorBoundary>
              <Suspense fallback={<LoadingComponent />}>
                {isConnected && activeTab === 'token' && <TokenBankFrontend />}
                
                <div className="divide-y divide-gray-200">
                  <div className="py-4 text-base leading-6 space-y-8 text-gray-700 sm:text-lg sm:leading-7">
                    {!isConnected ? (
                      <p className="text-center">请先连接钱包以使用应用功能</p>
                    ) : activeTab === 'nft' ? (
                      <NFTMarketplace />
                    ) : activeTab === 'transfers' ? (
                      <TokenTransferHistory />
                    ) : null}
                  </div>
                </div>
              </Suspense>
            </ErrorBoundary>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App; 