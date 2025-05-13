import React, { useState } from 'react';
import { useAccount, useSignMessage } from 'wagmi';

// 简化版SIWE认证组件
export default function SIWEAuth() {
  const { address, isConnected } = useAccount();
  const { signMessageAsync } = useSignMessage();
  const [authStatus, setAuthStatus] = useState<'unauthenticated' | 'authenticated' | 'authenticating'>('unauthenticated');
  const [error, setError] = useState<string | null>(null);

  // 创建简化的签名消息
  const signIn = async () => {
    try {
      if (!address) return;
      
      setAuthStatus('authenticating');
      setError(null);
      
      // 简化的消息
      const messageToSign = `登录NFT市场应用\n\n地址: ${address}\n时间: ${new Date().toISOString()}`;
      
      try {
        // 调用签名
        await signMessageAsync({
          message: messageToSign,
        });
        
        // 模拟验证成功
        setAuthStatus('authenticated');
      } catch (err) {
        console.error('签名失败:', err);
        setError('认证失败，请重试');
        setAuthStatus('unauthenticated');
      }
      
    } catch (err) {
      console.error('SIWE认证失败:', err);
      setError('认证失败，请重试');
      setAuthStatus('unauthenticated');
    }
  };

  // 登出
  const signOut = () => {
    setAuthStatus('unauthenticated');
  };

  if (!isConnected) {
    return null;
  }

  return (
    <div className="mt-4">
      {authStatus === 'unauthenticated' && (
        <button
          onClick={signIn}
          className="px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700"
        >
          使用以太坊账户登录
        </button>
      )}
      
      {authStatus === 'authenticating' && (
        <p className="text-gray-600">认证中，请在钱包中确认...</p>
      )}
      
      {authStatus === 'authenticated' && (
        <div>
          <p className="text-green-600 mb-2">✓ 已通过以太坊账户认证</p>
          <button
            onClick={signOut}
            className="px-4 py-2 font-bold text-white bg-red-500 rounded hover:bg-red-700"
          >
            退出登录
          </button>
        </div>
      )}
      
      {error && (
        <p className="text-red-500 mt-2">{error}</p>
      )}
    </div>
  );
} 