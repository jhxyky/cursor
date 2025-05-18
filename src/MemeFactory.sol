// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MemeToken.sol";

/**
 * @title MemeFactory
 * @dev 使用最小代理模式创建Meme代币的工厂合约
 */
contract MemeFactory {
    // 项目方地址
    address public immutable owner;
    // 项目方收费比例（1%）
    uint256 public constant FEE_PERCENT = 1;
    // 最小代理合约的基础合约地址
    address public immutable implementation;
    // 创建者 => 他们创建的Meme代币数组
    mapping(address => address[]) public creatorToMemes;
    
    // 事件
    event MemeCreated(address indexed creator, address indexed tokenAddress, string symbol);
    event MemeMinted(address indexed minter, address indexed tokenAddress, uint256 amount);

    constructor() {
        owner = msg.sender;
        
        // 部署实现合约作为模板
        implementation = address(new MemeToken("IMPL", 0, 0, 0, address(this)));
    }
    
    /**
     * @dev 通过最小代理模式部署新的Meme代币
     * @param symbol 代币符号
     * @param totalSupply 代币总供应量
     * @param perMint 每次铸造数量
     * @param price 每次铸造价格(wei)
     */
    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address tokenAddress) {
        // 创建代理合约
        tokenAddress = _createClone();
        
        // 初始化代理合约
        MemeToken(tokenAddress).initialize(symbol, totalSupply, perMint, price, msg.sender);
        
        // 记录创建者的Meme代币
        creatorToMemes[msg.sender].push(tokenAddress);
        
        emit MemeCreated(msg.sender, tokenAddress, symbol);
    }
    
    /**
     * @dev 铸造已部署的Meme代币
     * @param tokenAddr Meme代币合约地址
     */
    function mintInscription(address tokenAddr) external payable {
        MemeToken token = MemeToken(tokenAddr);
        
        // 检查合约是否存在并有效
        require(token.factory() == address(this), "Invalid token contract");
        
        // 检查价格
        require(msg.value >= token.mintPrice(), "Insufficient payment");
        
        // 分配费用
        uint256 ownerFee = (msg.value * FEE_PERCENT) / 100;
        uint256 creatorFee = msg.value - ownerFee;
        
        // 发送费用给项目方
        (bool success1, ) = owner.call{value: ownerFee}("");
        require(success1, "Transfer to owner failed");
        
        // 发送费用给创建者
        (bool success2, ) = token.creator().call{value: creatorFee}("");
        require(success2, "Transfer to creator failed");
        
        // 铸造代币
        token.mint(msg.sender);
        
        emit MemeMinted(msg.sender, tokenAddr, token.mintAmount());
    }
    
    /**
     * @dev 获取创建者创建的所有Meme代币
     * @param creator 创建者地址
     */
    function getCreatorMemes(address creator) external view returns (address[] memory) {
        return creatorToMemes[creator];
    }
    
    /**
     * @dev 创建最小代理合约
     * 使用EIP-1167标准的最小代理模式
     */
    function _createClone() internal returns (address instance) {
        bytes20 targetBytes = bytes20(implementation);
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, clone, 0x37)
        }
        
        require(instance != address(0), "Clone creation failed");
    }
} 