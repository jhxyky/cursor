// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title JiaoToken
 * @dev ERC20代币合约，支持EIP2612的离线签名授权(permit)
 */
contract JiaoToken is ERC20Permit, Ownable {
    constructor() ERC20("JiaoToken", "JIAO") ERC20Permit("JiaoToken") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18); // 铸造1,000,000个代币
    }
   
    /**
     * @dev 铸造新的代币
     * @param to 接收者地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}