import { useState, useEffect } from 'react';
import { ethers, providers } from 'ethers';
import { TokenBankABI } from '../constants/abis';
import { TokenBankAddress } from '../constants/addresses';

declare global {
  interface Window {
    ethereum: providers.ExternalProvider;
  }
}

const TokenBank = () => {
  const [balance, setBalance] = useState('0');
  const [userBalance, setUserBalance] = useState('0');
  const [depositAmount, setDepositAmount] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchBalances();
  }, []);

  const fetchBalances = async () => {
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const bankContract = new ethers.Contract(TokenBankAddress, TokenBankABI, signer);
      
      const accounts = await provider.listAccounts();
      if (accounts.length > 0) {
        const userDepositBalance = await bankContract.getDeposit(accounts[0]);
        setUserBalance(ethers.utils.formatEther(userDepositBalance));
        
        const totalBalance = await bankContract.balanceOf(TokenBankAddress);
        setBalance(ethers.utils.formatEther(totalBalance));
      }
    } catch (error) {
      console.error('获取余额时出错:', error);
      setError('获取余额失败');
    }
  };

  const handleDeposit = async () => {
    if (!depositAmount) return;
    setLoading(true);
    setError('');
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const bankContract = new ethers.Contract(TokenBankAddress, TokenBankABI, signer);
      
      const tx = await bankContract.deposit(ethers.utils.parseEther(depositAmount));
      await tx.wait();
      
      await fetchBalances();
      setDepositAmount('');
    } catch (error) {
      console.error('存款时出错:', error);
      setError('存款失败');
    } finally {
      setLoading(false);
    }
  };

  const handleWithdraw = async () => {
    if (!withdrawAmount) return;
    setLoading(true);
    setError('');
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const bankContract = new ethers.Contract(TokenBankAddress, TokenBankABI, signer);
      
      const tx = await bankContract.withdraw();
      await tx.wait();
      
      await fetchBalances();
      setWithdrawAmount('');
    } catch (error) {
      console.error('取款时出错:', error);
      setError('取款失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg">
      <h2 className="text-2xl font-bold mb-6 text-center text-gray-800">Token Bank</h2>
      
      {error && (
        <div className="mb-4 p-3 bg-red-100 text-red-700 rounded">
          {error}
        </div>
      )}
      
      <div className="mb-6 p-4 bg-gray-50 rounded-lg">
        <p className="text-gray-600">总存款余额:</p>
        <p className="text-2xl font-bold text-gray-800">{balance} ETH</p>
      </div>
      
      <div className="mb-6 p-4 bg-gray-50 rounded-lg">
        <p className="text-gray-600">您的存款余额:</p>
        <p className="text-2xl font-bold text-gray-800">{userBalance} ETH</p>
      </div>

      <div className="mb-4">
        <label className="block text-gray-700 mb-2">存款金额</label>
        <div className="flex gap-2">
          <input
            type="number"
            value={depositAmount}
            onChange={(e) => setDepositAmount(e.target.value)}
            className="flex-1 p-2 border rounded"
            placeholder="输入ETH数量"
            disabled={loading}
          />
          <button
            onClick={handleDeposit}
            disabled={loading || !depositAmount}
            className={`px-4 py-2 text-white rounded ${
              loading || !depositAmount ? 'bg-gray-400' : 'bg-blue-500 hover:bg-blue-600'
            }`}
          >
            {loading ? '处理中...' : '存款'}
          </button>
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-gray-700 mb-2">取款金额</label>
        <div className="flex gap-2">
          <input
            type="number"
            value={withdrawAmount}
            onChange={(e) => setWithdrawAmount(e.target.value)}
            className="flex-1 p-2 border rounded"
            placeholder="输入ETH数量"
            disabled={loading}
          />
          <button
            onClick={handleWithdraw}
            disabled={loading || !withdrawAmount}
            className={`px-4 py-2 text-white rounded ${
              loading || !withdrawAmount ? 'bg-gray-400' : 'bg-blue-500 hover:bg-blue-600'
            }`}
          >
            {loading ? '处理中...' : '取款'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default TokenBank; 