import React, { useState, useEffect } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { parseEther } from 'viem';
import { NFTMarketAddress, NFTContractAddress, WETHAddress } from '../constants/addresses';

// NFT上架和展示组件
export default function NFTMarketplace() {
  const { address, isConnected } = useAccount();
  const [nfts, setNfts] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  // 合约ABI简化版
  const nftMarketAbi = [
    {
      "inputs": [
        {"internalType": "address", "name": "nftContract", "type": "address"},
        {"internalType": "uint256", "name": "tokenId", "type": "uint256"},
        {"internalType": "address", "name": "token", "type": "address"},
        {"internalType": "uint256", "name": "price", "type": "uint256"}
      ],
      "name": "listNFT",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"internalType": "address", "name": "nftContract", "type": "address"},
        {"internalType": "uint256", "name": "tokenId", "type": "uint256"}
      ],
      "name": "purchaseNFT",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  const nftAbi = [
    {
      "inputs": [
        {"internalType": "address", "name": "operator", "type": "address"},
        {"internalType": "bool", "name": "approved", "type": "bool"}
      ],
      "name": "setApprovalForAll",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  // 使用writeContract代替write属性
  const { writeContractAsync: approveNFTs } = useWriteContract();
  const { writeContractAsync: listNFTAsync } = useWriteContract();
  const { writeContractAsync: purchaseNFTAsync } = useWriteContract();

  // 查询已上架的NFT (模拟数据)
  const fetchListedNFTs = async () => {
    setIsLoading(true);
    try {
      // 在实际项目中，这里应该从合约事件中获取所有上架的NFT
      // 这里仅为演示，使用模拟数据
      const mockNFTs = [
        {
          nftContract: NFTContractAddress,
          tokenId: '1',
          seller: '0x1234567890abcdef1234567890abcdef12345678',
          token: WETHAddress,
          price: '1000000000000000000', // 1 ETH
          isActive: true
        },
        {
          nftContract: NFTContractAddress,
          tokenId: '2',
          seller: '0x1234567890abcdef1234567890abcdef12345678',
          token: WETHAddress,
          price: '500000000000000000', // 0.5 ETH
          isActive: true
        }
      ];
      
      setNfts(mockNFTs);
    } catch (err) {
      console.error('获取NFT失败:', err);
      setError('获取NFT列表失败');
      setTimeout(() => setError(''), 3000);
    } finally {
      setIsLoading(false);
    }
  };

  // 组件加载时获取NFT列表
  useEffect(() => {
    if (isConnected) {
      fetchListedNFTs();
    }
  }, [isConnected]);

  // 处理NFT上架
  const handleListNFT = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tokenId || !price) {
      setError('请输入Token ID和价格');
      setTimeout(() => setError(''), 3000);
      return;
    }

    try {
      setIsLoading(true);
      
      // 首先授权NFT合约
      if (approveNFTs) {
        await approveNFTs({
          address: NFTContractAddress,
          abi: nftAbi,
          functionName: 'setApprovalForAll',
          args: [NFTMarketAddress, true]
        });
      }
      
      // 这里应该有一个延迟或等待交易确认的逻辑
      setTimeout(async () => {
        // 然后上架NFT
        if (listNFTAsync) {
          await listNFTAsync({
            address: NFTMarketAddress,
            abi: nftMarketAbi,
            functionName: 'listNFT',
            args: [
              NFTContractAddress,
              BigInt(tokenId),
              WETHAddress,
              parseEther(price)
            ]
          });
          setSuccess('NFT上架操作已执行，请在钱包中确认交易');
          setTimeout(() => setSuccess(''), 5000);
        }
      }, 2000);
      
    } catch (err) {
      console.error('上架NFT失败:', err);
      setError('上架NFT失败，请检查Token ID和价格是否正确');
      setTimeout(() => setError(''), 3000);
    } finally {
      setIsLoading(false);
    }
  };

  // 处理NFT购买
  const handlePurchaseNFT = async (nftContract: string, tokenId: string) => {
    try {
      setIsLoading(true);
      if (purchaseNFTAsync) {
        await purchaseNFTAsync({
          address: NFTMarketAddress,
          abi: nftMarketAbi,
          functionName: 'purchaseNFT',
          args: [nftContract, BigInt(tokenId)]
        });
        setSuccess('购买请求已发送，请在钱包中确认交易');
        setTimeout(() => setSuccess(''), 5000);
      }
    } catch (err) {
      console.error('购买NFT失败:', err);
      setError('购买NFT失败，请重试');
      setTimeout(() => setError(''), 3000);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isConnected) {
    return (
      <div className="py-4 text-center">
        <p className="text-gray-600">请先连接钱包以使用NFT市场功能</p>
      </div>
    );
  }

  return (
    <div className="py-4">
      <h2 className="text-2xl font-bold mb-4">NFT市场</h2>
      
      {/* 上架NFT表单 */}
      <div className="bg-white p-4 rounded-lg shadow mb-6">
        <h3 className="text-xl font-semibold mb-3">上架您的NFT</h3>
        <form onSubmit={handleListNFT} className="space-y-4">
          <div>
            <label className="block text-gray-700 mb-1">Token ID</label>
            <input
              type="text"
              value={tokenId}
              onChange={(e) => setTokenId(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
              placeholder="输入您拥有的NFT Token ID"
              disabled={isLoading}
            />
          </div>
          <div>
            <label className="block text-gray-700 mb-1">价格 (ETH)</label>
            <input
              type="text"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
              placeholder="设置价格，例如: 0.1"
              disabled={isLoading}
            />
          </div>
          <button
            type="submit"
            className={`w-full py-2 text-white font-semibold rounded ${
              isLoading
                ? 'bg-blue-300 cursor-not-allowed'
                : 'bg-blue-500 hover:bg-blue-600'
            }`}
            disabled={isLoading}
          >
            {isLoading ? '处理中...' : '上架NFT'}
          </button>
        </form>
      </div>
      
      {/* NFT列表 */}
      <div>
        <h3 className="text-xl font-semibold mb-3">可购买的NFT</h3>
        {isLoading ? (
          <p className="text-gray-600 text-center py-4">加载中...</p>
        ) : nfts.length === 0 ? (
          <p className="text-gray-600 text-center py-4">暂无可购买的NFT</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {nfts.map((nft, index) => (
              <div key={index} className="bg-white p-4 rounded-lg shadow">
                <div className="mb-2">
                  <span className="text-gray-500">NFT ID:</span> {nft.tokenId}
                </div>
                <div className="mb-2">
                  <span className="text-gray-500">卖家:</span> {nft.seller.substring(0, 6)}...{nft.seller.substring(nft.seller.length - 4)}
                </div>
                <div className="mb-3">
                  <span className="text-gray-500">价格:</span> {parseFloat(nft.price) / 1e18} ETH
                </div>
                <button
                  onClick={() => handlePurchaseNFT(nft.nftContract, nft.tokenId)}
                  className={`w-full py-2 text-white font-semibold rounded ${
                    isLoading
                      ? 'bg-green-300 cursor-not-allowed'
                      : 'bg-green-500 hover:bg-green-600'
                  }`}
                  disabled={isLoading || nft.seller.toLowerCase() === address?.toLowerCase()}
                >
                  {isLoading 
                    ? '处理中...' 
                    : nft.seller.toLowerCase() === address?.toLowerCase() 
                      ? '这是您的NFT' 
                      : '购买NFT'}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
      
      {/* 成功/错误消息 */}
      {success && (
        <div className="mt-4 p-3 bg-green-100 text-green-700 rounded">
          {success}
        </div>
      )}
      {error && (
        <div className="mt-4 p-3 bg-red-100 text-red-700 rounded">
          {error}
        </div>
      )}
    </div>
  );
} 