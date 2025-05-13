# NFT市场前端设置指南

## 已实现的功能

我们已经为NFT市场智能合约实现了一个完整的前端界面，包括以下功能：

1. **钱包连接**：使用Web3Modal和WalletConnect
2. **SIWE认证**：使用以太坊账户登录
3. **NFT上架**：允许用户上架他们的NFT并设置价格
4. **NFT购买**：允许用户浏览并购买上架的NFT
5. **账户切换**：支持在不同账户之间切换以测试功能

## 前端技术栈

- React + TypeScript
- Vite作为构建工具
- Wagmi用于以太坊交互
- Web3Modal/AppKit用于钱包连接UI
- SIWE用于以太坊身份验证
- TailwindCSS用于样式

## 启动应用前的必要步骤

1. **创建`.env`文件**

   在项目根目录创建一个`.env`文件，并添加以下内容：

   ```
   # 从https://cloud.walletconnect.com获取项目ID
   VITE_WALLETCONNECT_PROJECT_ID=你的WalletConnect项目ID
   
   # Sepolia测试网RPC URL
   VITE_SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
   ```

2. **安装依赖**

   ```bash
   npm install
   # 或
   pnpm install
   ```

3. **启动开发服务器**

   ```bash
   npm run dev
   # 或
   pnpm run dev
   ```

## 完整的测试流程

要完整测试NFT市场功能，请按照以下步骤操作：

1. **准备工作**
   - 确保在Sepolia测试网上有一些测试ETH
   - 确保已铸造一些测试NFT (使用我们的MyNFT合约)
   - 在手机上安装支持WalletConnect的钱包应用

2. **连接钱包**
   - 打开应用
   - 点击"连接钱包"按钮
   - 选择WalletConnect
   - 使用手机扫描QR码

3. **上架NFT**
   - 输入您拥有的NFT的Token ID
   - 设置价格
   - 点击"上架NFT"按钮
   - 在钱包中确认两个交易（批准和上架）

4. **切换账号测试购买**
   - 断开当前钱包连接
   - 使用不同账号重新连接
   - 浏览可购买的NFT
   - 选择一个NFT点击"购买NFT"
   - 在钱包中确认交易

## 文件结构说明

- `src/components/ConnectWallet.tsx` - 钱包连接组件
- `src/components/SIWEAuth.tsx` - SIWE认证组件
- `src/components/NFTMarketplace.tsx` - NFT市场主界面
- `src/config/web3modal.tsx` - Web3Modal配置
- `src/App.tsx` - 主应用组件
- `src/main.tsx` - 应用入口点

## 注意事项

- 此前端连接到Sepolia测试网
- 所有交易都需要测试网ETH支付gas费
- 确保在`.env`文件中设置了有效的WalletConnect项目ID
- 如果交易失败，请检查智能合约的错误消息

## 故障排除

- 如果无法连接钱包，确保您的WalletConnect项目ID正确
- 如果交易失败，检查您是否有足够的测试网ETH
- 如果上架失败，确保您是NFT的实际拥有者
- 如果购买失败，确保您有足够的代币支付NFT价格 