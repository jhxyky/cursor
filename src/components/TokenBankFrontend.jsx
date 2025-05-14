import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useAccount, useNetwork, useWalletClient, usePublicClient } from 'wagmi';
import { SiweMessage } from 'siwe';
import { PERMIT2_ADDRESS } from '@uniswap/permit2-sdk';
import { permitTransferFrom } from '@uniswap/permit2-sdk';

// 导入合约ABI
import TokenBankABI from '../abis/TokenBank.json';
import TokenABI from '../abis/JiaoToken.json';

const TokenBankFrontend = () => {
  const [amount, setAmount] = useState('');
  const [balance, setBalance] = useState('0');
  const [bankBalance, setBankBalance] = useState('0');
  const [isLoading, setIsLoading] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');

  // Contract addresses - replace with your deployed contract addresses
  const TOKEN_ADDRESS = process.env.REACT_APP_TOKEN_ADDRESS;
  const TOKEN_BANK_ADDRESS = process.env.REACT_APP_TOKEN_BANK_ADDRESS;

  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();

  useEffect(() => {
    if (isConnected && address) {
      fetchBalances();
    }
  }, [isConnected, address]);

  const fetchBalances = async () => {
    try {
      if (!publicClient || !TOKEN_ADDRESS || !TOKEN_BANK_ADDRESS) return;

      // 获取用户代币余额
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TokenABI, publicClient);
      const userBalance = await tokenContract.balanceOf(address);
      setBalance(ethers.utils.formatEther(userBalance));

      // 获取用户在Bank中的余额
      const bankContract = new ethers.Contract(TOKEN_BANK_ADDRESS, TokenBankABI, publicClient);
      const userBankBalance = await bankContract.balanceOf(address);
      setBankBalance(ethers.utils.formatEther(userBankBalance));
    } catch (error) {
      console.error('Error fetching balances:', error);
      setStatusMessage('获取余额失败');
    }
  };

  // 传统存款方法
  const handleDeposit = async () => {
    if (!amount || !isConnected || !walletClient) {
      setStatusMessage('请输入金额并连接钱包');
      return;
    }

    setIsLoading(true);
    setStatusMessage('处理存款中...');

    try {
      const amountWei = ethers.utils.parseEther(amount);

      // 创建合约实例
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TokenABI, walletClient);

      // 批准银行合约使用代币
      const approveTx = await tokenContract.approve(TOKEN_BANK_ADDRESS, amountWei);
      await approveTx.wait();
      setStatusMessage('授权成功，正在存款...');

      // 执行存款
      const bankContract = new ethers.Contract(TOKEN_BANK_ADDRESS, TokenBankABI, walletClient);
      const depositTx = await bankContract.deposit(amountWei);
      await depositTx.wait();

      setStatusMessage('存款成功!');
      setAmount('');
      fetchBalances();
    } catch (error) {
      console.error('Deposit error:', error);
      setStatusMessage('存款失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  // 使用EIP2612 permit进行存款
  const handlePermitDeposit = async () => {
    if (!amount || !isConnected || !walletClient) {
      setStatusMessage('请输入金额并连接钱包');
      return;
    }

    setIsLoading(true);
    setStatusMessage('处理签名授权存款中...');

    try {
      const amountWei = ethers.utils.parseEther(amount);
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TokenABI, walletClient);
      const bankContract = new ethers.Contract(TOKEN_BANK_ADDRESS, TokenBankABI, walletClient);

      // 获取nonce
      const nonce = await tokenContract.nonces(address);
      
      // 设置有效期
      const deadline = Math.floor(Date.now() / 1000) + 3600; // 1小时后
      
      // 准备签名数据
      const domain = {
        name: await tokenContract.name(),
        version: '1',
        chainId: chain.id,
        verifyingContract: TOKEN_ADDRESS
      };
      
      const types = {
        Permit: [
          { name: 'owner', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' }
        ]
      };
      
      const value = {
        owner: address,
        spender: TOKEN_BANK_ADDRESS,
        value: amountWei.toString(),
        nonce: nonce.toHexString(),
        deadline
      };
      
      // 请求用户签名
      const signature = await walletClient.signTypedData({
        domain,
        types,
        value
      });
      
      // 将签名分解为v, r, s
      const sig = ethers.utils.splitSignature(signature);
      
      // 调用permitDeposit函数
      const tx = await bankContract.permitDeposit(
        amountWei,
        deadline,
        sig.v,
        sig.r,
        sig.s
      );
      await tx.wait();
      
      setStatusMessage('Permit存款成功!');
      setAmount('');
      fetchBalances();
    } catch (error) {
      console.error('Permit deposit error:', error);
      setStatusMessage('Permit存款失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  // 使用Permit2进行存款
  const handlePermit2Deposit = async () => {
    if (!amount || !isConnected || !walletClient) {
      setStatusMessage('请输入金额并连接钱包');
      return;
    }

    setIsLoading(true);
    setStatusMessage('处理Permit2签名授权存款中...');

    try {
      const amountWei = ethers.utils.parseEther(amount);
      const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TokenABI, walletClient);
      
      // 批准Permit2合约使用代币（只需执行一次，之后可以重复使用）
      // 检查当前授权
      const allowance = await tokenContract.allowance(address, PERMIT2_ADDRESS);
      if (allowance.lt(amountWei)) {
        const approveTx = await tokenContract.approve(PERMIT2_ADDRESS, ethers.constants.MaxUint256);
        await approveTx.wait();
        setStatusMessage('已授权Permit2使用代币，准备签名...');
      }
      
      // 创建permit2签名数据
      const deadline = Math.floor(Date.now() / 1000) + 3600; // 1小时后
      const nonce = Math.floor(Math.random() * 1000000); // 随机nonce
      
      // 使用@uniswap/permit2-sdk创建签名
      const permit = {
        permitted: {
          token: TOKEN_ADDRESS,
          amount: amountWei.toString()
        },
        spender: TOKEN_BANK_ADDRESS,
        nonce,
        deadline
      };
      
      // 请求用户签名
      const { domain, types, values } = permitTransferFrom(
        permit,
        PERMIT2_ADDRESS,
        chain.id,
      );
      
      const signature = await walletClient.signTypedData({
        domain,
        types,
        value: values
      });
      
      // 调用depositWithPermit2函数
      const bankContract = new ethers.Contract(TOKEN_BANK_ADDRESS, TokenBankABI, walletClient);
      const tx = await bankContract.depositWithPermit2(
        nonce,
        deadline,
        amountWei,
        signature
      );
      await tx.wait();
      
      setStatusMessage('Permit2存款成功!');
      setAmount('');
      fetchBalances();
    } catch (error) {
      console.error('Permit2 deposit error:', error);
      setStatusMessage('Permit2存款失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl my-8 p-6">
      <h2 className="text-2xl font-bold mb-4">Token Bank</h2>
      
      {isConnected ? (
        <div>
          <div className="mb-4">
            <p className="text-gray-600">Your Token Balance: {balance} JIAO</p>
            <p className="text-gray-600">Your Bank Balance: {bankBalance} JIAO</p>
          </div>
          
          <div className="mb-4">
            <label className="block text-gray-700 mb-2">Deposit Amount</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              placeholder="Enter amount"
            />
          </div>
          
          <div className="flex flex-col space-y-2">
            <button
              onClick={handleDeposit}
              disabled={isLoading}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            >
              Standard Deposit
            </button>
            
            <button
              onClick={handlePermitDeposit}
              disabled={isLoading}
              className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            >
              Deposit with Permit
            </button>
            
            <button
              onClick={handlePermit2Deposit}
              disabled={isLoading}
              className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            >
              Deposit with Permit2
            </button>
          </div>
          
          {statusMessage && (
            <div className="mt-4 text-center text-sm">
              <p>{statusMessage}</p>
            </div>
          )}
        </div>
      ) : (
        <div className="text-center py-4">
          <p>Please connect your wallet to use Token Bank</p>
        </div>
      )}
    </div>
  );
};

export default TokenBankFrontend; 