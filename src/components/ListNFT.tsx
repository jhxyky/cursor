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

    // 检查 NFT 所有权
    const { data: owner } = useReadContract({
        address: NFTContractAddress,
        abi: NFTMarketABI,
        functionName: 'ownerOf',
        args: [tokenId ? BigInt(tokenId) : BigInt(0)],
        query: {
            enabled: !!tokenId,
        },
    }) as { data: `0x${string}` | undefined };

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

    const isOwner = owner && address && owner.toLowerCase() === address.toLowerCase();

    return (
        <div className="p-4 bg-white rounded-lg shadow-md">
            <h2 className="text-2xl font-bold mb-4">上架 NFT</h2>
            <div className="space-y-4">
                <div>
                    <label className="block text-sm font-medium text-gray-700">Token ID</label>
                    <input
                        type="number"
                        value={tokenId}
                        onChange={(e) => setTokenId(e.target.value)}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        placeholder="输入 NFT 的 Token ID"
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium text-gray-700">价格 (WETH)</label>
                    <input
                        type="number"
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        placeholder="输入价格"
                        step="0.01"
                    />
                </div>
                {!isOwner && tokenId && (
                    <p className="text-red-500">您不是这个 NFT 的所有者</p>
                )}
                <div className="flex space-x-4">
                    <button
                        onClick={handleApprove}
                        disabled={!tokenId || isApproving || isApprovingTx || !isOwner}
                        className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:bg-gray-400"
                    >
                        {isApproving || isApprovingTx ? '批准中...' : '批准'}
                    </button>
                    <button
                        onClick={handleList}
                        disabled={!tokenId || !price || isListing || isListingTx || !isOwner}
                        className="px-4 py-2 bg-green-500 text-white rounded-md hover:bg-green-600 disabled:bg-gray-400"
                    >
                        {isListing || isListingTx ? '上架中...' : '上架'}
                    </button>
                </div>
                {approveData && (
                    <p className="text-sm text-gray-500">
                        批准交易: {approveData}
                    </p>
                )}
                {listData && (
                    <p className="text-sm text-gray-500">
                        上架交易: {listData}
                    </p>
                )}
            </div>
        </div>
    );
} 