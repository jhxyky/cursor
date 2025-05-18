// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MemeToken
 * @dev 实现ERC20标准的Meme代币
 * 这是一个用作最小代理模板的基础合约
 */
contract MemeToken is ERC20, Ownable {
    uint256 public maxSupply;
    uint256 public mintAmount;
    uint256 public mintPrice;
    uint256 public totalMinted;
    address public factory;
    address public creator;
    bool private initialized;
    string private tokenName;
    string private tokenSymbol;

    /**
     * @dev 构造函数仅用于实现合约
     */
    constructor(
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address _creator
    ) ERC20("Implementation", "IMPL") Ownable(msg.sender) {
        // 实现合约不需要初始化，只有代理合约需要
    }

    /**
     * @dev 初始化函数，代理合约调用
     * @param _symbol 代币符号
     * @param _totalSupply 代币总供应量
     * @param _perMint 每次铸造的数量
     * @param _price 每个代币铸造的价格(wei)
     * @param _creator 代币创建者地址
     */
    function initialize(
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address _creator
    ) external {
        require(!initialized, "Already initialized");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0, "Mint amount must be greater than 0");
        require(_perMint <= _totalSupply, "Mint amount cannot exceed total supply");
        require(_creator != address(0), "Creator cannot be zero address");
        
        _transferOwnership(_creator);
        
        tokenName = string(abi.encodePacked("Meme ", _symbol));
        tokenSymbol = _symbol;
        
        maxSupply = _totalSupply;
        mintAmount = _perMint;
        mintPrice = _price;
        factory = msg.sender;
        creator = _creator;
        initialized = true;
    }

    /**
     * @dev 覆盖ERC20的name()函数
     */
    function name() public view override returns (string memory) {
        return initialized ? tokenName : "Implementation";
    }

    /**
     * @dev 覆盖ERC20的symbol()函数
     */
    function symbol() public view override returns (string memory) {
        return initialized ? tokenSymbol : "IMPL";
    }

    /**
     * @dev 铸造新代币
     * @param recipient 接收者地址
     */
    function mint(address recipient) external {
        require(msg.sender == factory, "Only factory can mint");
        require(totalMinted + mintAmount <= maxSupply, "Exceeds total supply");
        
        totalMinted += mintAmount;
        _mint(recipient, mintAmount);
    }
} 