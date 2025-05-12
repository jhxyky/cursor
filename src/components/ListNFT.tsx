import { useState } from 'react';
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { NFTMarketABI } from '../constants/abis';
import { NFTMarketAddress, NFTContractAddress, WETHAddress } from '../constants/addresses';

export function ListNFT() {
    const { address } = useAccount();
    const [tokenId, setTokenId] = useState<string>('');
    const [price, setPrice] = useState<string>('');
    const [isApproving, setIsApproving] = useState(false);
    const [isListing, setIsListing] = useState(false);

    // 批准 NFTMarket 合约转移 NFT
    const { writeContract: approve, data: approveData } = useWriteContract();

    // 等待批准交易完成
    const { isLoading: isApprovingTx } = useWaitForTransactionReceipt({
        hash: approveData,
    });

    // 上架 NFT
    const { writeContract: listNFT, data: listData } = useWriteContract();

    // 等待上架交易完成
    const { isLoading: isListingTx } = useWaitForTransactionReceipt({
        hash: listData,
    });

    const handleApprove = async () => {
        if (!tokenId) return;
        setIsApproving(true);
        try {
            await approve({
                address: NFTContractAddress,
                abi: NFTMarketABI,
                functionName: 'approve',
                args: [NFTMarketAddress, BigInt(tokenId)],
            });
        } catch (error) {
            console.error('批准失败:', error);
        } finally {
            setIsApproving(false);
        }
    };

    const handleList = async () => {
        if (!tokenId || !price) return;
        setIsListing(true);
        try {
            await listNFT({
                address: NFTMarketAddress,
                abi: NFTMarketABI,
                functionName: 'listNFT',
                args: [
                    NFTContractAddress,
                    BigInt(tokenId),
                    WETHAddress,
                    parseEther(price),
                ],
            });
        } catch (error) {
            console.error('上架失败:', error);
        } finally {
            setIsListing(false);
        }
    };

    return (
        <div className="p-4 bg-white rounded-lg shadow-md">
            <h2 className="text-2xl font-bold mb-4">上架 NFT</h2>
            <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2">
                    Token ID
                </label>
                    <input
                        type="number"
                        value={tokenId}
                        onChange={(e) => setTokenId(e.target.value)}
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                    placeholder="输入 NFT Token ID"
                    />
                </div>
            <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2">
                    价格 (ETH)
                </label>
                    <input
                        type="number"
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                        placeholder="输入价格"
                        step="0.01"
                    />
                </div>
                <div className="flex space-x-4">
                    <button
                        onClick={handleApprove}
                    disabled={isApproving || isApprovingTx || !tokenId}
                    className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline disabled:opacity-50"
                    >
                    {isApproving || isApprovingTx ? '批准中...' : '批准 NFT'}
                    </button>
                    <button
                        onClick={handleList}
                    disabled={isListing || isListingTx || !tokenId || !price}
                    className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline disabled:opacity-50"
                    >
                    {isListing || isListingTx ? '上架中...' : '上架 NFT'}
                    </button>
            </div>
            <p className="mt-4 text-sm text-gray-600">
                注意：上架前请确保您已经获得了该 NFT 的转移授权。
            </p>
        </div>
    );
} 