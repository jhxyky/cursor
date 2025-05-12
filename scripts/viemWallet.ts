import 'dotenv/config';
import { createPublicClient, createWalletClient, http, parseEther, formatEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { generatePrivateKey } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import { program } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join } from 'path';

// ERC20 代币 ABI
const ERC20_ABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "transfer",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;

// 配置文件路径
const CONFIG_PATH = join(process.cwd(), '.wallet-config.json');

// 创建客户端
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(process.env.SEPOLIA_RPC_URL)
});

// 保存配置
const saveConfig = (config: any) => {
  writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
};

// 加载配置
const loadConfig = () => {
  if (!existsSync(CONFIG_PATH)) {
    return { accounts: [] };
  }
  return JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
};

// 生成新账户
const generateAccount = async () => {
  const privateKey = generatePrivateKey();
  const account = privateKeyToAccount(privateKey);
  
  console.log(chalk.green('\n新账户已生成:'));
  console.log(chalk.yellow('地址:', account.address));
  console.log(chalk.yellow('私钥:', privateKey));
  
  const config = loadConfig();
  config.accounts.push({
    address: account.address,
    privateKey: privateKey
  });
  saveConfig(config);
  
  console.log(chalk.green('\n账户信息已保存到配置文件'));
};

// 查询余额
const checkBalance = async (address: `0x${string}`) => {
  try {
    const balance = await publicClient.getBalance({ address });
    console.log(chalk.green('\n账户余额:'));
    console.log(chalk.yellow(formatEther(balance), 'ETH'));
  } catch (error) {
    console.error(chalk.red('查询余额失败:', error));
  }
};

// 转账 ERC20 代币
const transferERC20 = async (
  tokenAddress: `0x${string}`,
  fromPrivateKey: `0x${string}`,
  toAddress: `0x${string}`,
  amount: string
) => {
  try {
    const account = privateKeyToAccount(fromPrivateKey);
    
    const walletClient = createWalletClient({
      account,
      chain: sepolia,
      transport: http(process.env.SEPOLIA_RPC_URL)
    });

    // 构建交易
    const { request } = await publicClient.simulateContract({
      address: tokenAddress,
      abi: ERC20_ABI,
      functionName: 'transfer',
      args: [toAddress, parseEther(amount)],
      account: account
    });

    // 发送交易
    const hash = await walletClient.writeContract(request);
    
    console.log(chalk.green('\n交易已发送!'));
    console.log(chalk.yellow('交易哈希:', hash));
    console.log(chalk.yellow('Sepolia 浏览器链接:', `https://sepolia.etherscan.io/tx/${hash}`));
    
    // 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(chalk.green('\n交易已确认!'));
    console.log(chalk.yellow('区块号:', receipt.blockNumber));
    console.log(chalk.yellow('Gas 使用:', receipt.gasUsed.toString()));
  } catch (error) {
    console.error(chalk.red('转账失败:', error));
  }
};

// 主菜单
const showMainMenu = async () => {
  const { action } = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: '请选择操作:',
      choices: [
        { name: '生成新账户', value: 'generate' },
        { name: '查询账户余额', value: 'balance' },
        { name: '转账 ERC20 代币', value: 'transfer' },
        { name: '退出', value: 'exit' }
      ]
    }
  ]);

  switch (action) {
    case 'generate':
      await generateAccount();
      break;
    case 'balance':
      const { address } = await inquirer.prompt([
        {
          type: 'input',
          name: 'address',
          message: '请输入要查询的地址:'
        }
      ]);
      await checkBalance(address as `0x${string}`);
      break;
    case 'transfer':
      const config = loadConfig();
      if (config.accounts.length === 0) {
        console.log(chalk.red('没有可用的账户，请先生成账户'));
        break;
      }

      const { tokenAddress, fromPrivateKey, toAddress, amount } = await inquirer.prompt([
        {
          type: 'input',
          name: 'tokenAddress',
          message: '请输入 ERC20 代币合约地址:'
        },
        {
          type: 'input',
          name: 'fromPrivateKey',
          message: '请输入发送账户的私钥(以0x开头):'
        },
        {
          type: 'input',
          name: 'toAddress',
          message: '请输入接收地址:'
        },
        {
          type: 'input',
          name: 'amount',
          message: '请输入转账金额:'
        }
      ]);

      await transferERC20(
        tokenAddress as `0x${string}`,
        fromPrivateKey as `0x${string}`,
        toAddress as `0x${string}`,
        amount
      );
      break;
    case 'exit':
      process.exit(0);
  }

  // 显示主菜单
  await showMainMenu();
};

// 启动程序
console.log(chalk.blue('欢迎使用 Viem 命令行钱包!'));
showMainMenu().catch(console.error); 