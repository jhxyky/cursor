# 环境变量配置指南

为了确保NFT市场前端正常运行，您需要正确配置环境变量。以下是详细的设置步骤：

## 获取WalletConnect项目ID

1. 访问 [WalletConnect Cloud](https://cloud.walletconnect.com/)
2. 创建一个账户并登录
3. 点击"Create a New Project"
4. 填写项目名称（例如"NFT Market"）
5. 复制生成的"Project ID"

## 创建环境变量文件

1. 在项目根目录创建一个名为`.env`的文件
2. 添加以下内容：

```
# WalletConnect项目ID，替换为您自己的ID
VITE_WALLETCONNECT_PROJECT_ID=您的WalletConnect项目ID

# Sepolia测试网RPC URL
VITE_SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
```

## 注意事项

- `.env`文件不应提交到Git仓库（已在.gitignore中配置）
- 确保项目ID正确无误
- 如果使用其他测试网，可以修改RPC URL
- 启动应用前确保已保存`.env`文件

## 验证配置

启动应用后，可以通过以下方式验证配置是否正确：

1. 打开浏览器开发者工具
2. 尝试连接钱包
3. 如果能看到钱包连接对话框，说明WalletConnect配置正确
4. 如果连接失败，请检查控制台错误信息

## 本地开发环境变量

如果您需要在本地开发环境使用不同的配置，可以创建`.env.local`文件，它会覆盖`.env`中的配置：

```
# 本地开发使用的WalletConnect项目ID
VITE_WALLETCONNECT_PROJECT_ID=本地开发项目ID

# 本地测试网RPC URL (例如使用Ganache)
VITE_SEPOLIA_RPC_URL=http://localhost:8545
```

## 故障排除

如果遇到环境变量相关的问题：

1. 确认`.env`文件位于项目根目录
2. 验证WalletConnect项目ID正确
3. 重启开发服务器以应用新的环境变量
4. 检查控制台是否有与环境变量相关的错误

只有正确配置环境变量，NFT市场前端才能正常连接钱包和与区块链交互。 