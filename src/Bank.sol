// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
在 该挑战 的 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
要求存款金额 >0.001 ether（用modifier权限控制）
BigBank 合约支持转移管理员
编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
Admin 合约的Owner地  址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。
*/

/// @title IBank 接口 - 标准存款和取款方法
interface IBank {
    function deposit() external payable;
    function withdraw() external;
}

/// @title Bank 合约 - 记录余额 + 排行榜功能
contract Bank is IBank {
    address public admin; // 管理员地址
    mapping(address => uint256) public balances; // 用户地址 => 存款余额
    address[3] public topUsers; // 存储前三名存款最多的用户

    constructor() {
        admin = msg.sender; // 部署合约的人是管理员
    }

    /// @notice 用户存款
    function deposit() external payable virtual override {
        require(msg.value > 0, "Deposit must be greater than 0");

        balances[msg.sender] += msg.value; // 更新用户余额

        _updateTopUsers(msg.sender); // 更新排行榜
    }

    /// @notice 管理员提取合约内全部余额
    function withdraw() external override {
        require(msg.sender == admin, "Only admin can withdraw");

        payable(admin).transfer(address(this).balance); // 转账给管理员
    }

    /// @notice 内部函数：更新存款排行榜
    function _updateTopUsers(address user) internal {
        for (uint256 i = 0; i < 3; i++) {
            // 如果位置为空，直接插入
            if (topUsers[i] == address(0)) {
                topUsers[i] = user;
                break;
            }

            // 如果当前用户余额更大且不是同一个用户
            if (balances[user] > balances[topUsers[i]] && user != topUsers[i]) {
                // 往后挪一位
                for (uint256 j = 2; j > i; j--) {
                    topUsers[j] = topUsers[j-1];
                }
                topUsers[i] = user;
                break;
            }
        }
    }

    /// @notice 查询某个用户余额
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}

/// @title BigBank 合约 - 继承 Bank，并增加限制
contract BigBank is Bank {
    // 存款必须大于 0.001 ETH
    modifier onlyBigDeposit() {
        require(msg.value > 0.001 ether, "Deposit must be > 0.001 ether");
        _;
    }

    /// @notice 重写 deposit，加上金额限制
    function deposit() external payable override onlyBigDeposit {
        balances[msg.sender] += msg.value;
        _updateTopUsers(msg.sender);
    }

    /// @notice 管理员更换
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can transfer admin");
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }
}

/// @title Admin 合约 - 管理 Bank / BigBank 的资金转移
contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender; // 部署者是 owner
    }

    /// @notice 调用 Bank 的 withdraw，从银行合约取钱到 Admin 合约
    function adminWithdraw(IBank bank) external {
        require(msg.sender == owner, "Only owner can withdraw");
        bank.withdraw(); // 通过接口调用
    }

    /// @notice 用于接收银行合约转过来的 ETH
    receive() external payable {}
}