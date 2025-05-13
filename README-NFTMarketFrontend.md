# NFT市场前端应用

这个前端应用允许用户连接钱包、上架NFT和购买NFT。它使用了以下技术：

- React + Vite
- Wagmi (与以太坊交互)
- Web3Modal (钱包连接UI)
- SIWE (Sign-In with Ethereum 认证)
- AppKit (用户友好的Web3组件)

## 准备工作

在开始之前，请确保：

1. 已安装Node.js (v16+)和npm/pnpm
2. 拥有一个WalletConnect项目ID (从https://cloud.walletconnect.com获取)
3. 安装了手机钱包应用（如MetaMask、Coinbase Wallet、Trust Wallet等）

## 配置步骤

1. 克隆仓库后，创建`.env`文件并添加以下内容：

```
# WalletConnect项目ID，从https://cloud.walletconnect.com获取
VITE_WALLETCONNECT_PROJECT_ID=你的WalletConnect项目ID

# Sepolia测试网RPC URL
VITE_SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
```

2. 安装依赖：

```bash
npm install
# 或
pnpm install
```

3. 启动开发服务器：

```bash
npm run dev
# 或
pnpm run dev
```

## 使用指南

### 连接钱包

1. 打开应用后，点击右上角的"连接钱包"按钮
2. 选择WalletConnect选项
3. 使用手机扫描显示的二维码
4. 在手机钱包中确认连接请求

### 使用SIWE登录

1. 连接钱包后，点击"使用以太坊账户登录"按钮
2. 在钱包中确认签名请求
3. 签名成功后，您将看到登录成功的提示

### 上架NFT

1. 确保您拥有一些NFT (本应用使用地址为`NFTContractAddress`的NFT合约)
2. 在"上架您的NFT"部分，输入您拥有的NFT的Token ID
3. 设置您希望出售的价格（以ETH为单位）
4. 点击"上架NFT"按钮
5. 在钱包中确认两个交易：
   - 首先批准NFT合约操作权限
   - 然后确认上架交易

### 购买NFT

1. 在"可购买的NFT"部分浏览上架的NFT
2. 找到您感兴趣的NFT，点击"购买NFT"按钮
3. 在钱包中确认交易
4. 交易成功后，NFT将转移到您的账户

## 切换账号

要测试从不同账号购买NFT的功能：

1. 点击"断开连接"按钮断开当前钱包
2. 重新连接钱包，但这次在手机钱包应用中选择不同的账号
3. 现在您可以以新账号身份浏览和购买NFT

## 技术说明

- 前端使用Wagmi库与以太坊区块链交互
- Web3Modal/AppKit提供了用户友好的钱包连接界面
- SIWE (Sign-In with Ethereum) 允许用户使用他们的以太坊账户进行身份验证
- 应用连接到Sepolia测试网络

## 问题排查

如果遇到问题：

1. 确保您的钱包中有足够的Sepolia测试网ETH
2. 检查控制台是否有错误信息
3. 确保您的环境变量设置正确
4. 确保您使用的NFT合约地址是正确的
5. 如果交易失败，检查智能合约的错误信息 