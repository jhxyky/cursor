import React from 'react';
import ConnectWallet from './components/ConnectWallet';
import SIWEAuth from './components/SIWEAuth';
import TokenBankFrontend from './components/TokenBankFrontend';
import NFTMarketplace from './components/NFTMarketplace';
import { useAccount } from 'wagmi';

function App() {
  const { isConnected } = useAccount();

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
            
            {isConnected && <TokenBankFrontend />}
            
            <div className="divide-y divide-gray-200">
              <div className="py-8 text-base leading-6 space-y-8 text-gray-700 sm:text-lg sm:leading-7">
                {isConnected ? (
                  <NFTMarketplace />
                ) : (
                  <p className="text-center">请先连接钱包以使用NFT市场功能</p>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App; 