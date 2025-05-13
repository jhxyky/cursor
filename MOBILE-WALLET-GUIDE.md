# 手机钱包连接指南

本指南将帮助您设置和使用手机钱包连接到NFT市场前端应用，实现跨设备访问区块链功能。

## 推荐的手机钱包应用

以下是支持WalletConnect协议的主流手机钱包应用：

1. **MetaMask Mobile**
   - [Android下载](https://play.google.com/store/apps/details?id=io.metamask)
   - [iOS下载](https://apps.apple.com/us/app/metamask/id1438144202)
   - 功能全面，界面友好，最广泛使用的以太坊钱包

2. **Coinbase Wallet**
   - [Android下载](https://play.google.com/store/apps/details?id=org.toshi)
   - [iOS下载](https://apps.apple.com/us/app/coinbase-wallet-nfts-crypto/id1278383455)
   - 与Coinbase交易所集成，易于使用

3. **Trust Wallet**
   - [Android下载](https://play.google.com/store/apps/details?id=com.wallet.crypto.trustapp)
   - [iOS下载](https://apps.apple.com/us/app/trust-crypto-bitcoin-wallet/id1288339409)
   - 支持多链，界面简洁

4. **imToken**
   - [Android下载](https://play.google.com/store/apps/details?id=im.token.app)
   - [iOS下载](https://apps.apple.com/us/app/imtoken2/id1384798940)
   - 支持中文界面，对国内用户友好

## 设置步骤

### 第一次使用钱包

1. 下载并安装上述任一钱包应用
2. 创建新钱包（安全保存您的助记词和私钥！）
3. 设置密码和/或生物认证
4. 切换到Sepolia测试网：
   - MetaMask: 设置 > 网络 > 添加网络 > 添加Sepolia
   - Coinbase Wallet: 设置 > 网络 > Sepolia
   - Trust Wallet: 设置 > 偏好设置 > 网络 > Sepolia
   - imToken: 我 > 设置 > 网络管理 > 添加Sepolia

5. 获取测试网ETH：
   - 使用[Sepolia水龙头](https://sepoliafaucet.com/)获取免费测试ETH

### 连接到NFT市场应用

1. 在电脑浏览器中打开NFT市场应用
2. 点击"连接钱包"按钮
3. 选择"WalletConnect"选项
4. 屏幕上会显示一个QR码
5. 在手机钱包应用中：
   - MetaMask: 点击扫描按钮
   - Coinbase Wallet: 点击扫描QR码
   - Trust Wallet: 点击设置 > WalletConnect > 新建连接
   - imToken: 点击扫一扫
6. 扫描电脑屏幕上的QR码
7. 在手机上确认连接请求
8. 连接成功后，电脑上的应用界面会更新，显示您已连接

## 执行交易

当您在NFT市场应用中执行操作（如上架NFT或购买NFT）时：

1. 电脑上会发起交易请求
2. 手机上会收到推送通知
3. 打开钱包应用查看交易详情
4. 检查交易参数（例如gas费用、合约调用等）
5. 点击"确认"按钮批准交易
6. 等待交易完成，电脑应用会显示交易状态

## 切换账号测试购买

要测试从不同账号购买NFT的功能：

1. 在手机钱包中断开当前连接：
   - 大多数钱包中可在"设置 > WalletConnect > 活动连接"中找到
2. 在手机钱包中切换到另一个账号
3. 使用上面的步骤重新连接到NFT市场应用
4. 现在您可以以新账号身份浏览和购买NFT

## 安全提示

1. **永远不要分享您的私钥或助记词**
2. 定期更新钱包应用到最新版本
3. 在测试网上操作前，确保您使用的是测试网络，而不是主网
4. 对于不熟悉的dApp，在确认交易之前仔细检查交易详情
5. 使用完应用后，记得断开钱包连接

## 故障排除

- **无法扫描QR码**: 确保手机相机清晰并有足够光线
- **连接失败**: 检查手机和电脑是否连接到同一WiFi网络
- **交易未出现在手机上**: 尝试重新扫描QR码重新连接
- **签名请求被拒绝**: 检查钱包应用中的权限设置
- **交易失败**: 检查是否有足够的测试网ETH支付gas费用

通过遵循此指南，您可以轻松地使用手机钱包连接到NFT市场应用，并执行各种区块链交易操作。 