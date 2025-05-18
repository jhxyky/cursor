# Meme代币发射平台实现总结

## 项目概述

本项目实现了一个使用最小代理（Minimal Proxy）模式的Meme代币发射平台。该平台允许用户以低Gas成本创建和部署自己的ERC20 Meme代币。关键特性包括：

1. 使用EIP-1167最小代理模式以降低部署成本
2. 支持自定义代币参数（符号、总供应量、铸造数量、价格）
3. 费用分配机制（1%给项目方，99%给Meme创建者）
4. 铸造限制，确保不超过总供应量

## 核心合约

项目包含两个主要合约：

### 1. MemeToken.sol

基础ERC20代币实现，作为代理合约的实现模板。主要功能：

- 支持通过`initialize`方法初始化代币（符号、供应量、铸造量等）
- 限制只有工厂合约可以调用铸造函数
- 追踪已铸造的代币数量，确保不超过总供应量

### 2. MemeFactory.sol

工厂合约，负责创建和管理Meme代币，实现最小代理模式。主要功能：

- `deployInscription`：部署新的Meme代币（通过克隆实现合约）
- `mintInscription`：铸造已部署的Meme代币并分配费用
- 费用分配机制（1%给项目方，99%给创建者）
- 记录创建者的所有Meme代币

## 最小代理模式

本项目使用EIP-1167标准的最小代理模式以降低Gas成本：

```solidity
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
```

这种模式只部署一次实现合约，然后通过部署小型代理合约来克隆其功能，大幅减少创建新代币的Gas成本。每个代理合约通过delegatecall将所有调用转发到实现合约。

## 测试结果

项目包含完整的测试套件，覆盖所有关键功能：

- ✅ 代币部署测试
- ✅ 代币铸造测试
- ✅ 多次铸造与供应量限制测试
- ✅ 支付验证测试
- ✅ 费用分配测试
- ✅ 创建者记录测试

所有测试均已通过，确保合约功能正常且安全。

## 使用案例

1. **创建新的Meme代币**：
   ```solidity
   // 创建者调用
   factory.deployInscription("PEPE", 1_000_000 * 10**18, 10_000 * 10**18, 0.01 ether);
   ```

2. **铸造Meme代币**：
   ```solidity
   // 用户调用，支付费用
   factory.mintInscription{value: 0.01 ether}(tokenAddress);
   ```

## 安全考量

- 合约包含严格的访问控制，确保只有工厂合约可以铸造代币
- 铸造限制确保不会超过总供应量
- 使用安全的资金转移模式
- 采用最新的Solidity版本（0.8.20）以获得内置的溢出保护 