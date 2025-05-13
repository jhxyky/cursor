// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title 简单的多签钱包合约
contract MultiSigWallet {
    // 事件声明
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    // 多签持有人地址数组
    address[] public owners;
    // 地址是否为多签持有人的映射
    mapping(address => bool) public isOwner;
    // 需要的确认数（门槛）
    uint public numConfirmationsRequired;

    // 交易结构体
    struct Transaction {
        address to;      // 目标地址  是啥
        uint value;      // 转账金额
        bytes data;      // 调用数据
        bool executed;   // 是否已执行
        uint numConfirmations;  // 已确认数
    }

    // 所有交易数组
    Transaction[] public transactions;
    // 交易的确认情况：交易索引 => 多签人地址 => 是否确认
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // 修饰器：仅多签持有人可调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // 修饰器：交易必须存在
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // 修饰器：交易未执行
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // 修饰器：交易未被当前调用者确认
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    /// @notice 构造函数：初始化多签持有人和确认门槛
    /// @param _owners 多签持有人地址数组
    /// @param _numConfirmationsRequired 需要的确认数
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        // 初始化多签持有人
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /// @notice 接收ETH的回调函数
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice 提交交易提案
    /// @param _to 目标地址
    /// @param _value 转账金额
    /// @param _data 调用数据
    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /// @notice 确认交易
    /// @param _txIndex 交易索引
    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// @notice 执行交易
    /// @param _txIndex 交易索引
    function executeTransaction(uint _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// @notice 撤销确认
    /// @param _txIndex 交易索引
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /// @notice 获取多签持有人数组
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @notice 获取交易数量
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    /// @notice 获取交易详情
    /// @param _txIndex 交易索引
    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
} 