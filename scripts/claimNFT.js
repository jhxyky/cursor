const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

async function main() {
    // 获取合约实例
    const market = await ethers.getContract("AirdropMerkleNFTMarket");
    const token = await ethers.getContract("MerkleToken");
    
    // 用户地址
    const userAddress = "0x..."; // 替换为实际用户地址
    
    // 构建白名单
    const whitelist = [userAddress];
    const leaves = whitelist.map(addr => keccak256(addr));
    const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const proof = merkleTree.getHexProof(keccak256(userAddress));
    
    // 获取签名
    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1小时后过期
    const value = ethers.parseEther("1"); // 授权金额
    
    const domain = {
        name: await token.name(),
        version: "1",
        chainId: await ethers.provider.getNetwork().then(n => n.chainId),
        verifyingContract: token.address
    };
    
    const types = {
        Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" }
        ]
    };
    
    const nonce = await token.nonces(userAddress);
    
    const permitData = {
        owner: userAddress,
        spender: market.address,
        value: value,
        nonce: nonce,
        deadline: deadline
    };
    
    const signature = await ethers.provider.send("eth_signTypedData_v4", [
        userAddress,
        JSON.stringify({
            types,
            primaryType: "Permit",
            domain,
            message: permitData
        })
    ]);
    
    const { r, s, v } = ethers.Signature.from(signature);
    
    // 准备 Multicall 数据
    const permitCalldata = market.interface.encodeFunctionData("permitPrePay", [
        userAddress,
        value,
        deadline,
        v,
        r,
        s
    ]);
    
    const claimCalldata = market.interface.encodeFunctionData("claimNFT", [
        1, // tokenId
        proof
    ]);
    
    // 执行 Multicall
    const multicallData = [permitCalldata, claimCalldata];
    const tx = await market.multicall(multicallData);
    await tx.wait();
    
    console.log("NFT claimed successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 