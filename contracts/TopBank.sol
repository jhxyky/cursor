// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TopBank
 * @dev 支持直接存款和排行榜功能的银行合约
 * 特点：
 * 1. 支持直接转账存款
 * 2. 记录每个地址的存款金额
 * 3. 使用双向链表维护前 10 名存款用户
 */
contract TopBank {
    // 链表节点结构
    struct User {
        address userAddress;      // 用户地址
        uint256 balance;         // 存款余额
        uint256 prev;           // 前一个节点的索引
        uint256 next;           // 后一个节点的索引
    }
    
    // 状态变量
    address public admin;                           // 管理员地址
    mapping(address => uint256) public balances;    // 用户余额映射
    mapping(address => uint256) public userIndex;   // 用户地址到链表索引的映射
    User[] public users;                           // 用户链表
    uint256 public constant MAX_RANK = 10;         // 排行榜最大容量
    uint256 public head;                           // 链表头部（最大余额）
    uint256 public tail;                           // 链表尾部（最小余额）
    uint256 public size;                           // 当前排行榜大小
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RankUpdated(address indexed user, uint256 newBalance, uint256 rank);
    
    /**
     * @dev 构造函数
     * 初始化链表，创建一个空节点作为哨兵
     */
    constructor() {
        admin = msg.sender;
        // 创建哨兵节点
        users.push(User(address(0), 0, 0, 0));
        head = 0;
        tail = 0;
        size = 0;
    }
    
    /**
     * @dev 接收直接转账的回调函数
     */
    receive() external payable {
        _deposit();
    }
    
    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        _deposit();
    }
    
    /**
     * @dev 内部存款处理函数
     */
    function _deposit() internal {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        uint256 newBalance = balances[msg.sender] + msg.value;
        balances[msg.sender] = newBalance;
        
        _updateRanking(msg.sender, newBalance);
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev 更新用户排名
     * @param user 用户地址
     * @param newBalance 新的余额
     */
    function _updateRanking(address user, uint256 newBalance) internal {
        uint256 currentIndex = userIndex[user];
        
        // 如果用户已在排行榜中
        if (currentIndex != 0) {
            _removeFromList(currentIndex);
            size--;
        }
        
        // 如果排行榜未满或新余额大于最小值
        if (size < MAX_RANK || (size == MAX_RANK && newBalance > users[tail].balance)) {
            // 从头开始查找插入位置
            uint256 current = head;
            while (current != 0 && users[current].balance > newBalance) {
                current = users[current].next;
            }
            
            // 创建新节点
            users.push(User(user, newBalance, 0, 0));
            uint256 newIndex = users.length - 1;
            userIndex[user] = newIndex;
            
            // 插入节点
            _insertBefore(current, newIndex);
            
            // 更新大小和尾部
            if (size < MAX_RANK) {
                size++;
            } else if (current == 0) {
                // 如果插入到末尾，移除原来的尾部
                _removeFromList(tail);
            }
            
            emit RankUpdated(user, newBalance, size);
        }
    }
    
    /**
     * @dev 从链表中移除节点
     * @param index 要移除的节点索引
     */
    function _removeFromList(uint256 index) internal {
        User storage user = users[index];
        
        if (user.prev != 0) {
            users[user.prev].next = user.next;
        } else {
            head = user.next;
        }
        
        if (user.next != 0) {
            users[user.next].prev = user.prev;
        } else {
            tail = user.prev;
        }
        
        userIndex[user.userAddress] = 0;
    }
    
    /**
     * @dev 在指定节点前插入新节点
     * @param beforeIndex 在此节点前插入
     * @param newIndex 要插入的新节点索引
     */
    function _insertBefore(uint256 beforeIndex, uint256 newIndex) internal {
        User storage newUser = users[newIndex];
        
        if (beforeIndex == 0) {
            // 插入到末尾
            if (tail == 0) {
                head = newIndex;
            } else {
                users[tail].next = newIndex;
                newUser.prev = tail;
            }
            tail = newIndex;
        } else {
            // 插入到中间
            User storage beforeUser = users[beforeIndex];
            newUser.next = beforeIndex;
            newUser.prev = beforeUser.prev;
            
            if (beforeUser.prev != 0) {
                users[beforeUser.prev].next = newIndex;
            } else {
                head = newIndex;
            }
            
            beforeUser.prev = newIndex;
        }
    }
    
    /**
     * @dev 获取排行榜
     * @return addresses 排行榜用户地址数组
     * @return amounts 对应的余额数组
     */
    function getTopUsers() external view returns (address[] memory addresses, uint256[] memory amounts) {
        addresses = new address[](size);
        amounts = new uint256[](size);
        
        uint256 current = head;
        for (uint256 i = 0; i < size && current != 0; i++) {
            addresses[i] = users[current].userAddress;
            amounts[i] = users[current].balance;
            current = users[current].next;
        }
        
        return (addresses, amounts);
    }
    
    /**
     * @dev 获取用户排名
     * @param user 用户地址
     * @return rank 排名（0表示未上榜）
     */
    function getUserRank(address user) external view returns (uint256 rank) {
        uint256 index = userIndex[user];
        if (index == 0) return 0;
        
        rank = 1;
        uint256 current = head;
        while (current != index && current != 0) {
            rank++;
            current = users[current].next;
        }
        
        return rank;
    }
    
    /**
     * @dev 提取存款
     * @param amount 提取金额
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        
        _updateRanking(msg.sender, balances[msg.sender]);
        
        emit Withdraw(msg.sender, amount);
    }
    
    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 管理员提取全部余额
     */
    function adminWithdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }
} 