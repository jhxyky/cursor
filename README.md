# 可升级 NFT 市场项目

这是一个基于 Foundry 框架开发的可升级 NFT 市场项目，包含可升级的 ERC721 NFT 合约和两个版本的市场合约。

## 功能特点

### NFT 合约 (MyNFT.sol)
- 基于 OpenZeppelin 的可升级 ERC721 标准
- 支持安全铸造功能
- 实现 UUPS 可升级模式

### 市场合约 V1 (NFTMarketplaceV1.sol)
- NFT 上架功能
- NFT 下架功能
- NFT 购买功能
- 可配置的市场费率
- 合约暂停功能
- 费用接收地址管理

### 市场合约 V2 (NFTMarketplaceV2.sol)
- 继承 V1 的所有功能
- 添加离线签名上架功能
- 使用 nonce 防止重放攻击
- EIP-712 类型化数据签名

## 项目结构

```
├── src/
│   ├── MyNFT.sol              # NFT 合约
│   ├── NFTMarketplaceV1.sol   # 市场合约 V1
│   └── NFTMarketplaceV2.sol   # 市场合约 V2
├── script/
│   ├── DeployMarketplace.s.sol # 部署脚本
│   └── UpgradeToV2.s.sol      # 升级脚本
└── test/
    └── NFTMarketplace.t.sol    # 测试文件
```

## 安装依赖

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

## 编译

```bash
forge build
```

## 测试

```bash
forge test -vvv
```

## 部署

1. 设置环境变量：
```bash
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url
```

2. 部署合约：
```bash
forge script script/DeployMarketplace.s.sol --rpc-url $RPC_URL --broadcast
```

3. 升级到 V2：
```bash
export MARKETPLACE_PROXY=deployed_proxy_address
forge script script/UpgradeToV2.s.sol --rpc-url $RPC_URL --broadcast
```

## 安全考虑

1. 使用 OpenZeppelin 的可升级合约标准
2. 实现合约暂停功能以应对紧急情况
3. 使用 nonce 机制防止签名重放攻击
4. 所有关键函数都有访问控制
5. 使用 SafeERC20 进行代币转账
6. 实现 EIP-712 标准进行类型化数据签名

## 测试覆盖

- 基本功能测试
  - NFT 上架
  - NFT 下架
  - NFT 购买
  - 费用计算和转账
- 升级功能测试
  - 合约升级
  - V2 新功能测试
- 安全性测试
  - 暂停功能
  - 访问控制
  - 签名验证
  - 异常情况处理

## 许可证

MIT
