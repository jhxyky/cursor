// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract esRNT {
    struct LockInfo {
        address user;
        uint64 startTime; 
        uint256 amount;
    }
    
    LockInfo[] private _locks;

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(
                address(uint160(i + 1)), 
                uint64(block.timestamp + i),
                1e18 * (i + 1)
            ));
        }
    }

    // 添加一个查询函数，方便验证
    function getLockInfo(uint256 index) public view returns (
        address user,
        uint64 startTime,
        uint256 amount
    ) {
        require(index < _locks.length, "Index out of bounds");
        LockInfo memory lock = _locks[index];
        return (lock.user, lock.startTime, lock.amount);
    }

    // 获取锁定总数
    function getLocksLength() public view returns (uint256) {
        return _locks.length;
    }
} 