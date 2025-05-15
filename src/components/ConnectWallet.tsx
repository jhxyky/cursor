import React, { useState, useEffect } from 'react';
import { useAccount, useDisconnect, useConnect } from 'wagmi';
import { useWeb3Modal } from '@web3modal/wagmi/react';
import { injected } from 'wagmi/connectors';

export default function ConnectWallet() {
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { connect } = useConnect();
  const modal = useWeb3Modal();
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [useDirectConnect, setUseDirectConnect] = useState(false);

  // 组件加载时检查Web3Modal是否可用
  useEffect(() => {
    console.log('ConnectWallet组件已加载');
    console.log('Web3Modal状态:', modal ? '已初始化' : '未初始化');
    console.log('isConnected:', isConnected);
    console.log('address:', address);
  }, [modal, isConnected, address]);

  // 格式化地址显示
  const formatAddress = (addr: string) => {
    return addr ? `${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}` : '';
  };

  // 直接连接MetaMask (备用方法)
  const handleDirectConnect = async () => {
    setIsConnecting(true);
    setError(null);
    
    try {
      console.log('尝试直接连接MetaMask...');
      connect({ connector: injected() });
      console.log('连接请求已发送');
    } catch (err) {
      const errorMsg = '直接连接钱包时出错: ' + (err instanceof Error ? err.message : String(err));
      console.error(errorMsg, err);
      setError(errorMsg);
    } finally {
      setIsConnecting(false);
    }
  };

  // 处理钱包连接
  const handleConnect = async () => {
    console.log('点击连接钱包');
    
    // 如果用户选择直接连接，绕过Web3Modal
    if (useDirectConnect) {
      return handleDirectConnect();
    }
    
    // 检查Web3Modal是否可用
    if (!modal || !modal.open) {
      const errorMsg = 'Web3Modal未正确初始化';
      console.error(errorMsg);
      setError(errorMsg);
      alert(errorMsg);
      // 提示用户切换到直接连接
      setUseDirectConnect(true);
      return;
    }

    setIsConnecting(true);
    setError(null);
    
    try {
      console.log('尝试打开Web3Modal...');
      // 打印所有可用方法
      console.log('Web3Modal可用方法:', Object.keys(modal));
      
      // 直接尝试打开modal
      await modal.open();
      console.log('Web3Modal已打开');
    } catch (err) {
      const errorMsg = '连接钱包时出错: ' + (err instanceof Error ? err.message : String(err));
      console.error(errorMsg, err);
      setError(errorMsg);
      // 如果Web3Modal失败，建议用户尝试直接连接
      setUseDirectConnect(true);
    } finally {
      setIsConnecting(false);
    }
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
        onClick={handleConnect}
        disabled={isConnecting}
        className={`px-4 py-2 text-sm font-bold text-white rounded ${
          isConnecting ? 'bg-blue-300' : 'bg-blue-500 hover:bg-blue-700'
        }`}
      >
        {isConnecting ? '连接中...' : useDirectConnect ? '直接连接MetaMask' : '连接钱包'}
      </button>
      
      {/* 切换连接方式 */}
      <button 
        onClick={() => setUseDirectConnect(!useDirectConnect)}
        className="text-xs text-blue-500 underline"
      >
        {useDirectConnect ? '使用Web3Modal连接' : '使用直接连接'}
      </button>
      
      {error && (
        <div className="text-center text-sm text-red-500 mt-1">
          {error}
        </div>
      )}
      
      <div className="text-center text-sm text-gray-500 mt-2">
        <p>支持MetaMask和WalletConnect，使用手机钱包扫描二维码连接</p>
      </div>
    </div>
  );
} 