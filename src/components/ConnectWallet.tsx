import React from 'react';
import { useAccount, useDisconnect } from 'wagmi';
import { useWeb3Modal } from '@web3modal/wagmi/react';

export default function ConnectWallet() {
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { open } = useWeb3Modal();

  // 格式化地址显示
  const formatAddress = (addr: string) => {
    return addr ? `${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}` : '';
  };

  if (isConnected && address) {
    return (
      <div className="flex items-center space-x-2">
        <span className="px-4 py-2 text-sm bg-gray-100 rounded">
          {formatAddress(address)}
        </span>
        <button
          onClick={() => disconnect()}
          className="px-4 py-2 text-sm font-bold text-white bg-red-500 rounded hover:bg-red-700"
        >
          断开连接
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col space-y-2">
      <button
        onClick={() => open()}
        className="px-4 py-2 text-sm font-bold text-white rounded bg-blue-500 hover:bg-blue-700"
      >
        连接钱包
      </button>
      
      <div className="text-center text-sm text-gray-500 mt-2">
        <p>支持MetaMask和WalletConnect，使用手机钱包扫描二维码连接</p>
      </div>
    </div>
  );
} 