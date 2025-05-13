# NFT市场使用指南

## 环境设置

1. 获取WalletConnect项目ID
   - 访问 https://cloud.walletconnect.com/
   - 创建一个账户并新建项目
   - 复制项目ID

2. 设置环境变量
   - 在项目根目录创建一个`.env`文件
   - 添加以下内容:
   ```
   VITE_WALLETCONNECT_PROJECT_ID=你的WalletConnect项目ID
   VITE_SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
   ```

## 安装手机钱包

1. 在手机上安装支持WalletConnect的钱包，例如:
   - MetaMask (iOS/Android)
   - Rainbow Wallet (iOS/Android)
   - Trust Wallet (iOS/Android)

2. 确保钱包已连接到Sepolia测试网络

## 使用流程

### 启动应用

```bash
npm run dev
```

### 连接钱包

1. 在网页上点击"连接钱包"按钮
2. 选择连接方式:
   - 电脑上已安装MetaMask的用户可以选择"MetaMask"
   - 使用手机钱包的用户可以选择"WalletConnect"
   - 如选择WalletConnect，将显示二维码，使用手机钱包扫描该二维码完成连接

### 以太坊账户登录(SIWE)

1. 连接钱包后，点击"使用以太坊账户登录"按钮
2. 在钱包中确认签名请求
3. 签名完成后，用户状态将变为"已登录"

### 上架NFT

1. 在"上架您的NFT"表单中:
   - 输入您拥有的NFT的Token ID
   - 输入希望出售的价格(以ETH为单位)
2. 点击"上架NFT"按钮
3. 在钱包中确认两个交易:
   - 第一个交易是授权NFT市场合约操作您的NFT
   - 第二个交易是将NFT上架到市场

### 购买NFT

1. 在"可购买的NFT"列表中，找到您想购买的NFT
2. 点击对应的"购买NFT"按钮
3. 在钱包中确认交易

## 切换账户测试

为了测试完整流程，您可以:
1. 使用一个账户上架NFT
2. 断开连接
3. 使用另一个账户连接(可以是手机钱包)
4. 购买刚才上架的NFT

## 常见问题

1. **交易失败**
   - 确保您的钱包有足够的测试网ETH
   - 确保连接的是Sepolia测试网

2. **NFT无法上架**
   - 确认您是否拥有该Token ID的NFT
   - 确认您是否已经给予NFT市场合约足够的授权

3. **连接问题**
   - 如果使用WalletConnect无法连接，请确认您的项目ID是否正确
   - 确保手机钱包支持WalletConnect协议 