import React, { useState, useEffect } from 'react';
import { useAccount, useWriteContract, usePublicClient } from 'wagmi';
import axios from 'axios';
import { parseEther, parseAbiItem } from 'viem';

// ERC20代币转账记录展示和转账功能组件
export default function TokenTransferHistory() {
  const { address, isConnected } = useAccount();
  const publicClient = usePublicClient();
  const [transfers, setTransfers] = useState<any[]>([]);
  const [events, setEvents] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  // 转账表单状态
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState('');
  const [isTransferring, setIsTransferring] = useState(false);

  // 使用writeContract钩子执行合约调用
  const { writeContractAsync: sendToken } = useWriteContract();
  
  // 代币合约地址
  const tokenAddress = '0xBC7281ab137A16a6772dE800aa2Dc3EFD61EE6aE';

  // 从区块链获取用户的转账记录
  const fetchTransferHistory = async () => {
    if (!address || !publicClient) return;
    
    setIsLoading(true);
    try {
      // 获取当前区块
      const currentBlock = await publicClient.getBlockNumber();
      
      // 查询从该地址发出的转账
      const sentLogs = await publicClient.getLogs({
        address: tokenAddress,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        fromBlock: currentBlock - BigInt(10000),
        toBlock: currentBlock,
        args: {
          from: address
        }
      });
      
      // 查询到该地址的转账
      const receivedLogs = await publicClient.getLogs({
        address: tokenAddress,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        fromBlock: currentBlock - BigInt(10000),
        toBlock: currentBlock,
        args: {
          to: address
        }
      });
      
      // 合并并处理日志
      const allLogs = [...sentLogs, ...receivedLogs];
      
      // 转换日志为转账记录
      const transferRecords = await Promise.all(allLogs.map(async (log) => {
        // 获取区块信息以获取时间戳
        const block = await publicClient.getBlock({
          blockNumber: log.blockNumber
        });
        
        return {
          from: log.args.from,
          to: log.args.to,
          value: log.args.value ? log.args.value.toString() : '0',
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
          timestamp: new Date(Number(block.timestamp) * 1000).toISOString()
        };
      }));
      
      // 按时间排序
      transferRecords.sort((a, b) => 
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      );
      
      setTransfers(transferRecords);
    } catch (err) {
      console.error('获取转账记录失败:', err);
      setError('获取转账记录失败，请确保连接到正确的网络');
      setTimeout(() => setError(''), 3000);
      
      // 如果获取失败，使用空数组
      setTransfers([]);
    } finally {
      setIsLoading(false);
    }
  };

  // 调用后端API保存转账记录
  const saveTransferToBackend = async (from: string, to: string, value: string, transactionHash: string) => {
    try {
      // 将转账详情转换为文本
      const amount = parseFloat(value) / 1e18;
      
      // 创建完整的交易信息JSON
      const transferData = {
        txHash: transactionHash,
        from: from,
        to: to,
        value: amount.toString(),
        tokenSymbol: 'JIAO',
        timestamp: new Date().toISOString(),
        type: 'ERC20_TRANSFER'
      };
      
      const transferText = JSON.stringify(transferData);
      
      // 构建请求数据
      const requestData = {
        address: transactionHash, // 使用交易哈希作为地址
        text: transferText
      };
      
      console.log('准备向后端发送请求...');
      console.log('请求URL: http://localhost:8080/api/saveEvenText');
      console.log('请求数据:', JSON.stringify(requestData, null, 2));
      
      // 设置请求配置，包括CORS相关选项
      const config = {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
          'X-Requested-With': 'XMLHttpRequest',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0'
        },
        withCredentials: false // 对于简单的跨域请求，通常不需要凭证
      };
      
      // 调用后端API
      const response = await axios.post(
        'http://192.168.5.41:8080/api/saveEvenText', 
        requestData,
        config
      );
      
      console.log('后端响应状态:', response.status);
      console.log('后端响应数据:', response.data);
      
      // 在UI上显示成功消息
      setSuccess(`${transferText} - 交易记录已保存到后端`);
      setTimeout(() => setSuccess(''), 5000);
      
      return response.data;
    } catch (error: any) {
      console.error('保存转账记录到后端失败');
      
      // 详细输出错误信息
      if (error.response) {
        // 服务器响应了错误状态码
        console.error('错误响应状态:', error.response.status);
        console.error('错误响应数据:', error.response.data);
      } else if (error.request) {
        // 请求发送但没有收到响应
        console.error('未收到响应，请检查后端服务是否运行:', error.request);
      } else {
        // 请求设置出错
        console.error('请求错误:', error.message);
      }
      
      // 在UI上显示错误消息
      setError(`保存转账记录失败: ${error.message || '后端服务未响应'}`);
      setTimeout(() => setError(''), 5000);
      
      throw error;
    }
  };

  // 处理转账
  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!toAddress || !amount) {
      setError('请输入收款地址和金额');
      setTimeout(() => setError(''), 3000);
      return;
    }
    
    if (!address) {
      setError('钱包未连接');
      setTimeout(() => setError(''), 3000);
      return;
    }
    
    try {
      setIsTransferring(true);
      
      // ERC20 代币的转账函数ABI
      const tokenAbi = [
        {
          "inputs": [
            { "internalType": "address", "name": "to", "type": "address" },
            { "internalType": "uint256", "name": "amount", "type": "uint256" }
          ],
          "name": "transfer",
          "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }],
          "stateMutability": "nonpayable",
          "type": "function"
        }
      ];
      
      // 转换金额为wei单位
      const amountInWei = parseEther(amount);
      
      // 执行转账交易
      const hash = await sendToken({
        address: tokenAddress,
        abi: tokenAbi,
        functionName: 'transfer',
        args: [toAddress, amountInWei]
      });
      
      console.log('转账交易已提交, 交易哈希:', hash);
      
      // 显示成功消息
      setSuccess(`转账已执行，交易哈希: ${hash}`);
      setTimeout(() => setSuccess(''), 5000);
      
      // 转账成功后调用后端API保存记录
      console.log('交易成功，开始向后端保存记录...');
      await saveTransferToBackend(address, toAddress, amountInWei.toString(), hash);
      console.log('向后端保存记录操作完成');
      
      // 清空输入框
      setToAddress('');
      setAmount('');
      
      // 刷新转账记录
      setTimeout(() => {
        fetchTransferHistory();
      }, 2000);
      
    } catch (err: any) {
      console.error('转账失败:', err);
      setError(`转账失败: ${err.message || '未知错误'}`);
      setTimeout(() => setError(''), 5000);
    } finally {
      setIsTransferring(false);
    }
  };

  // 获取转账记录和事件列表
  useEffect(() => {
    if (isConnected && address && publicClient) {
      fetchTransferHistory();
      fetchAllEvents();
    }
  }, [isConnected, address, publicClient]);

  // 索引转账记录并保存到后端数据库
  const indexTransferToBackend = async () => {
    if (!address || !publicClient) {
      setError('请先连接钱包');
      setTimeout(() => setError(''), 3000);
      return;
    }
    
    setIsLoading(true);
    try {
      // 获取当前区块
      const currentBlock = await publicClient.getBlockNumber();
      console.log('当前区块:', currentBlock.toString());
      
      // 批量查询ERC20 Token的历史转账事件
      console.log('开始查询Token合约地址的所有转账记录:', tokenAddress);
      
      // 查询该代币合约的所有转账记录
      const allTokenTransfers = await publicClient.getLogs({
        address: tokenAddress,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
        fromBlock: currentBlock - BigInt(50000), // 索引更多历史区块
        toBlock: currentBlock
      });
      
      console.log(`共发现 ${allTokenTransfers.length} 条转账记录`);
      
      if (allTokenTransfers.length === 0) {
        setSuccess('未发现转账记录');
        setTimeout(() => setSuccess(''), 3000);
        setIsLoading(false);
        return;
      }
      
      // 转换日志为转账记录
      let indexedCount = 0;
      
      for (const log of allTokenTransfers) {
        try {
          // 获取区块信息以获取时间戳
          const block = await publicClient.getBlock({
            blockNumber: log.blockNumber
          });
          
          const transferData = {
            from: log.args.from,
            to: log.args.to,
            value: log.args.value ? log.args.value.toString() : '0',
            blockNumber: log.blockNumber.toString(),
            transactionHash: log.transactionHash,
            timestamp: new Date(Number(block.timestamp) * 1000).toISOString()
          };
          
          // 将转账详情转换为文本
          const amount = parseFloat(transferData.value) / 1e18;
          
          // 创建完整的交易信息
          const transferText = JSON.stringify({
            txHash: transferData.transactionHash,
            blockNumber: transferData.blockNumber,
            from: transferData.from,
            to: transferData.to,
            value: amount.toString(),
            tokenSymbol: 'JIAO',
            timestamp: transferData.timestamp,
            type: 'ERC20_TRANSFER'
          });
          
          // 保存到后端
          await axios.post(
            'http://192.168.5.41:8080/api/saveEvenText',
            {
              address: transferData.transactionHash, // 使用交易哈希作为地址
              text: transferText
            },
            {
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json, text/plain, */*',
                'X-Requested-With': 'XMLHttpRequest',
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
                'Expires': '0'
              }
            }
          );
          
          indexedCount++;
          
          // 每索引5条记录更新一次状态
          if (indexedCount % 5 === 0) {
            setSuccess(`正在索引...已处理 ${indexedCount}/${allTokenTransfers.length} 条记录`);
          }
          
        } catch (err) {
          console.error('处理转账记录失败:', err);
          // 继续处理下一条记录
        }
      }
      
      setSuccess(`成功索引 ${indexedCount} 条历史转账记录到后端数据库`);
      setTimeout(() => setSuccess(''), 5000);
      
      // 刷新后端事件列表
      await fetchAllEvents();
      
    } catch (err: any) {
      console.error('索引转账记录失败:', err);
      setError(`索引转账记录失败: ${err.message || '未知错误'}`);
      setTimeout(() => setError(''), 5000);
    } finally {
      setIsLoading(false);
    }
  };

  // 格式化地址显示
  const formatAddress = (addr: string) => {
    return `${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}`;
  };

  // 格式化时间显示
  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN');
  };

  // 格式化代币金额显示
  const formatTokenAmount = (value: string) => {
    const amount = parseFloat(value) / 1e18; // 假设代币有18位小数
    return amount.toFixed(4);
  };

  // 判断交易类型（收款/付款）
  const getTransactionType = (transfer: any) => {
    if (!address) return '未知';
    if (transfer.to.toLowerCase() === address.toLowerCase()) {
      return '收款';
    } else if (transfer.from.toLowerCase() === address.toLowerCase()) {
      return '付款';
    }
    return '其他';
  };

  // 获取所有事件列表
  const fetchAllEvents = async () => {
    try {
      setIsLoading(true);
      console.log('获取事件列表...');
      
      const response = await axios.get(
        'http://192.168.5.41:8080/api/getAllEven',
        { 
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/plain, */*',
            'X-Requested-With': 'XMLHttpRequest',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Expires': '0'
          }, 
          timeout: 10000 // 增加超时时间
        }
      );
      
      console.log('事件列表数据:', response.data);
      setEvents(response.data);
      setSuccess('成功获取事件列表！');
      setTimeout(() => setSuccess(''), 3000);
      return response.data;
    } catch (err: any) {
      console.error('获取事件列表失败:', err);
      if (err.code === 'ECONNREFUSED') {
        console.error('连接被拒绝，确认服务器是否运行');
      }
      setError(`获取事件列表失败: ${err.message || '未知错误'}`);
      setTimeout(() => setError(''), 5000);
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  // 添加测试后端连接的功能
  const testBackendConnection = async () => {
    try {
      setIsLoading(true);
      console.log('测试后端连接...');
      
      // 简单的测试数据
      const testData = {
        address: address || '0x0000000000000000000000000000000000000000',
        text: '这是一条测试消息，用于验证与后端的连接'
      };
      
      const response = await axios.post(
        'http://192.168.5.41:8080/api/saveEvenText',
        testData,
        { 
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/plain, */*',
            'X-Requested-With': 'XMLHttpRequest',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Expires': '0'
          }, 
          timeout: 10000 // 增加超时时间
        }
      );
      
      console.log('完整响应数据:', response);
      setSuccess('后端连接测试成功！');
      setTimeout(() => setSuccess(''), 5000);
      
      // 测试成功后获取最新事件列表
      await fetchAllEvents();
    } catch (err) {
      console.error('详细错误:', err);
      if (err.code === 'ECONNREFUSED') {
        console.error('连接被拒绝，确认服务器是否运行');
      }
      setError(`后端连接测试失败: ${err.message || '未知错误'}`);
      setTimeout(() => setError(''), 5000);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isConnected) {
    return (
      <div className="py-4 text-center">
        <p className="text-gray-600">请先连接钱包以查看转账记录</p>
      </div>
    );
  }

  return (
    <div className="py-4">
      <h2 className="text-2xl font-bold mb-4">JIAO代币转账</h2>
      
      {/* 转账表单 */}
      <div className="bg-white p-4 rounded-lg shadow mb-6">
        <h3 className="text-xl font-semibold mb-3">发送代币</h3>
        <form onSubmit={handleTransfer} className="space-y-4">
          <div>
            <label className="block text-gray-700 mb-1">收款地址</label>
            <input
              type="text"
              value={toAddress}
              onChange={(e) => setToAddress(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
              placeholder="输入有效的以太坊地址"
              disabled={isTransferring}
            />
          </div>
          <div>
            <label className="block text-gray-700 mb-1">金额</label>
            <input
              type="text"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded"
              placeholder="输入转账金额"
              disabled={isTransferring}
            />
          </div>
          <button
            type="submit"
            className={`w-full py-2 text-white font-semibold rounded ${
              isTransferring
                ? 'bg-blue-300 cursor-not-allowed'
                : 'bg-blue-500 hover:bg-blue-600'
            }`}
            disabled={isTransferring}
          >
            {isTransferring ? '转账中...' : '发送代币'}
          </button>
        </form>
      </div>
      
      {/* 测试后端连接按钮和索引转账按钮 */}
      <div className="mb-6">
        <button
          onClick={testBackendConnection}
          className="px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600 mr-2"
          disabled={isLoading}
        >
          {isLoading ? '测试中...' : '测试后端连接'}
        </button>
        <button
          onClick={indexTransferToBackend}
          className="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600 mr-2"
          disabled={isLoading}
        >
          {isLoading ? '索引中...' : '索引历史转账到数据库'}
        </button>
        <span className="text-sm text-gray-500">
          (点击索引按钮可将区块链上的历史转账记录保存到后端数据库)
        </span>
      </div>
      
      {error && (
        <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-4">
          <p>{error}</p>
        </div>
      )}
      
      {success && (
        <div className="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-4">
          <p>{success}</p>
        </div>
      )}
      
      {/* 转账记录标题 */}
      <h2 className="text-2xl font-bold mb-4 mt-8">代币转账记录</h2>
      
      {isLoading ? (
        <div className="text-center py-4">
          <p className="text-gray-600">加载中...</p>
        </div>
      ) : transfers.length === 0 ? (
        <div className="text-center py-4">
          <p className="text-gray-600">暂无转账记录</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  类型
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  对方地址
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  金额
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  时间
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  交易哈希
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {transfers.map((transfer, index) => {
                const transactionType = getTransactionType(transfer);
                const counterpartyAddress = transactionType === '收款' ? transfer.from : transfer.to;
                
                return (
                  <tr key={index} className={transactionType === '收款' ? 'bg-green-50' : ''}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        transactionType === '收款' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {transactionType}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatAddress(counterpartyAddress)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      {formatTokenAmount(transfer.value)} JIAO
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatTimestamp(transfer.timestamp)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <a 
                        href={`https://sepolia.etherscan.io/tx/${transfer.transactionHash}`} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:text-blue-800"
                      >
                        {formatAddress(transfer.transactionHash)}
                      </a>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
      
      <div className="mt-4">
        <button
          onClick={fetchTransferHistory}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 mr-2"
        >
          刷新转账记录
        </button>
        <button
          onClick={fetchAllEvents}
          className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
        >
          刷新事件列表
        </button>
      </div>
      
      {/* 事件列表 */}
      <h2 className="text-2xl font-bold mb-4 mt-8">后端事件列表</h2>
      
      {isLoading ? (
        <div className="text-center py-4">
          <p className="text-gray-600">加载中...</p>
        </div>
      ) : events.length === 0 ? (
        <div className="text-center py-4">
          <p className="text-gray-600">暂无事件记录</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  地址
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  内容
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  创建时间
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {events.map((event, index) => (
                <tr key={index} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {event.id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {event.address}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {(() => {
                      try {
                        // 尝试解析JSON
                        const transactionData = JSON.parse(event.text);
                        return (
                          <div>
                            <p><strong>从:</strong> {formatAddress(transactionData.from)}</p>
                            <p><strong>至:</strong> {formatAddress(transactionData.to)}</p>
                            <p><strong>金额:</strong> {transactionData.value} {transactionData.tokenSymbol}</p>
                            <p><strong>交易哈希:</strong> {formatAddress(transactionData.txHash)}</p>
                            <p><strong>时间:</strong> {new Date(transactionData.timestamp).toLocaleString('zh-CN')}</p>
                          </div>
                        );
                      } catch (e) {
                        // 不是JSON格式，直接显示文本
                        return event.text;
                      }
                    })()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {event.createTime}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
} 