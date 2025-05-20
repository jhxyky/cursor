// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/TopBank.sol";

contract TopBankTest is Test {
    TopBank public bank;
    address public admin;
    address[] public users;
    
    function setUp() public {
        admin = makeAddr("admin");
        vm.startPrank(admin);
        bank = new TopBank();
        vm.stopPrank();
        
        // 创建测试用户
        for(uint i = 0; i < 15; i++) {
            users.push(makeAddr(string(abi.encodePacked("user", vm.toString(i)))));
            vm.deal(users[i], 100 ether);
        }
    }
    
    function testDirectDeposit() public {
        address user = users[0];
        vm.startPrank(user);
        
        // 测试直接转账
        payable(address(bank)).transfer(1 ether);
        assertEq(bank.balances(user), 1 ether);
        
        // 测试通过 deposit 函数存款
        bank.deposit{value: 2 ether}();
        assertEq(bank.balances(user), 3 ether);
        
        vm.stopPrank();
    }
    
    function testRankingSystem() public {
        // 模拟 12 个用户存款，金额递增
        for(uint i = 0; i < 12; i++) {
            vm.startPrank(users[i]);
            bank.deposit{value: (i + 1) * 1 ether}();
            vm.stopPrank();
        }
        
        // 获取前 10 名用户
        (address[] memory topAddresses, uint256[] memory amounts) = bank.getTopUsers();
        
        // 验证排行榜长度
        assertEq(topAddresses.length, 10);
        assertEq(amounts.length, 10);
        
        // 验证排序是否正确（从大到小）
        for(uint i = 0; i < 9; i++) {
            assertTrue(amounts[i] >= amounts[i + 1]);
        }
        
        // 验证最后两个用户未上榜
        assertEq(bank.getUserRank(users[10]), 0);
        assertEq(bank.getUserRank(users[11]), 0);
    }
    
    function testUpdateRanking() public {
        // 初始存款
        vm.startPrank(users[0]);
        bank.deposit{value: 1 ether}();
        vm.stopPrank();
        
        vm.startPrank(users[1]);
        bank.deposit{value: 2 ether}();
        vm.stopPrank();
        
        // 更新存款金额
        vm.startPrank(users[0]);
        bank.deposit{value: 3 ether}();
        vm.stopPrank();
        
        // 验证排名更新
        (address[] memory topAddresses,) = bank.getTopUsers();
        assertEq(topAddresses[0], users[0]);
        assertEq(topAddresses[1], users[1]);
    }
    
    function testWithdraw() public {
        address user = users[0];
        vm.startPrank(user);
        
        // 存款
        bank.deposit{value: 5 ether}();
        uint256 initialBalance = user.balance;
        
        // 提取部分金额
        bank.withdraw(2 ether);
        
        // 验证余额变化
        assertEq(bank.balances(user), 3 ether);
        assertEq(user.balance, initialBalance + 2 ether);
        
        vm.stopPrank();
    }
    
    function testAdminWithdraw() public {
        // 用户存款
        vm.startPrank(users[0]);
        bank.deposit{value: 5 ether}();
        vm.stopPrank();
        
        uint256 initialAdminBalance = admin.balance;
        
        // 管理员提取
        vm.startPrank(admin);
        bank.adminWithdraw();
        vm.stopPrank();
        
        // 验证余额转移
        assertEq(address(bank).balance, 0);
        assertEq(admin.balance, initialAdminBalance + 5 ether);
    }
    
    function testFailNonAdminWithdraw() public {
        vm.startPrank(users[0]);
        vm.expectRevert("Only admin can withdraw");
        bank.adminWithdraw();
        vm.stopPrank();
    }
    
    function testFailInsufficientWithdraw() public {
        address user = users[0];
        vm.startPrank(user);
        
        bank.deposit{value: 1 ether}();
        vm.expectRevert("Insufficient balance");
        bank.withdraw(2 ether);
        
        vm.stopPrank();
    }
} 