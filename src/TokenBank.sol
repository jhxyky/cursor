// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPermit2.sol";

/**
 * @title TokenBank
 * @dev 代币存款合约，支持EIP2612的离线签名授权(permit)进行存款
 */
contract TokenBank is Ownable, ReentrancyGuard {
    IERC20 public token;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastDepositTimestamp;
    
    // Permit2合约地址
    address public immutable permit2;
    
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _token, address _permit2) Ownable(msg.sender) {
        token = IERC20(_token);
        permit2 = _permit2;
    }

    /**
     * @dev 常规存款方法，需要先approve
     * @param amount 存款金额
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        lastDepositTimestamp[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev 使用EIP2612 permit进行授权存款
     * @param amount 存款金额
     * @param deadline 签名截止时间
     * @param v 签名v
     * @param r 签名r
     * @param s 签名s
     */
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // 使用permit进行授权
        IERC20Permit(address(token)).permit(
            msg.sender,    // 代币持有者
            address(this), // 被授权者(合约地址)
            amount,        // 授权金额
            deadline,      // 签名截止时间
            v, r, s        // 签名部分
        );
        
        // 转账代币到合约
        token.transferFrom(msg.sender, address(this), amount);
        
        // 更新余额和时间戳
        balances[msg.sender] += amount;
        lastDepositTimestamp[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev 使用Permit2进行授权存款
     * @param nonce 随机数
     * @param deadline 签名截止时间
     * @param amount 存款金额
     * @param signature permit2签名
     */
    function depositWithPermit2(
        uint256 nonce,
        uint256 deadline,
        uint256 amount,
        bytes calldata signature
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(permit2 != address(0), "Permit2 not configured");
        
        // 构建Permit2所需的数据结构
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: nonce,
            deadline: deadline
        });
        
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: amount
        });
        
        // 调用Permit2合约执行授权转账
        IPermit2(permit2).permitTransferFrom(
            permit,
            transferDetails,
            msg.sender,
            signature
        );
        
        // 更新余额和时间戳
        balances[msg.sender] += amount;
        lastDepositTimestamp[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev 取款方法
     * @param amount 取款金额
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev 查询用户余额
     * @param user 用户地址
     * @return 余额
     */
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
} 