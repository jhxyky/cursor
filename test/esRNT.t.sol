// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/esRNT.sol";

contract esRNTTest is Test {
    esRNT public token;

    function setUp() public {
        token = new esRNT();
    }

    function testLockInfo() public {
        // 验证数组长度
        assertEq(token.getLocksLength(), 11);

        // 验证第一个锁定信息
        (address user, uint64 startTime, uint256 amount) = token.getLockInfo(0);
        assertEq(user, address(1));
        assertTrue(startTime > 0);
        assertEq(amount, 1e18);

        // 验证最后一个锁定信息
        (user, startTime, amount) = token.getLockInfo(10);
        assertEq(user, address(11));
        assertTrue(startTime > 0);
        assertEq(amount, 11e18);
    }

    // 测试存储布局
    function testStorageLayout() public {
        bytes32 slot0 = vm.load(address(token), bytes32(uint256(0)));
        // 验证数组长度是否为 11
        assertEq(uint256(slot0), 11);

        // 计算数组存储的起始位置
        bytes32 arraySlot = keccak256(abi.encode(uint256(0)));
        
        // 读取第一个 LockInfo
        bytes32 userSlot = vm.load(address(token), arraySlot);
        assertEq(address(uint160(uint256(userSlot))), address(1));
    }
} 