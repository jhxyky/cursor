// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {BigBank} from "../src/Bank.sol";
import {Admin} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    BigBank public bigBank;
    Admin public adminContract;
    address admin;
    address user1;
    address user2;
    address user3;
    address user4;

    function setUp() public {
        bank = new Bank();
        bigBank = new BigBank();
        adminContract = new Admin();
        admin = bank.admin(); // 部署者就是 admin

        // 创建 4 个测试用户
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        user4 = address(0x4);

        // 给用户一些以太币
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
    }

    function testDepositUpdatesBalance() public {
        // 用户1存 1ETH
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        assertEq(bank.getBalance(user1), 1 ether);
    }

    function testDepositZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("Deposit must be greater than 0");
        bank.deposit{value: 0}();
    }

    function testTopUsersRanking() public {
        // 只有 1 个用户
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        assertEq(bank.topUsers(0), user1);

        // 2 个用户
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        assertEq(bank.topUsers(0), user2);
        assertEq(bank.topUsers(1), user1);

        // 3 个用户
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        assertEq(bank.topUsers(0), user3);
        assertEq(bank.topUsers(1), user2);
        assertEq(bank.topUsers(2), user1);

        // 4 个用户，user4 存 0.5ETH，榜单不会变
        vm.prank(user4);
        bank.deposit{value: 0.5 ether}();
        assertEq(bank.topUsers(0), user3);
        assertEq(bank.topUsers(1), user2);
        assertEq(bank.topUsers(2), user1);

        // user1 再存 3ETH，总共4ETH，应该排第一
        vm.prank(user1);
        bank.deposit{value: 3 ether}();
        assertEq(bank.topUsers(0), user1);
    }

    function testOnlyAdminCanWithdraw() public {
        // 先存一点钱
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        // 非管理员尝试 withdraw，应该 revert
        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        bank.withdraw();

        // 管理员成功 withdraw
        uint256 adminBalanceBefore = admin.balance;

        vm.prank(admin);
        bank.withdraw();

        uint256 adminBalanceAfter = admin.balance;
        assertTrue(adminBalanceAfter > adminBalanceBefore);
    }

    function testBigBankMinimumDeposit() public {
        vm.prank(user1);
        vm.expectRevert("Deposit must be > 0.001 ether");
        bigBank.deposit{value: 0.0005 ether}();

        // 测试正常存款
        vm.prank(user1);
        bigBank.deposit{value: 0.002 ether}();
        assertEq(bigBank.getBalance(user1), 0.002 ether);
    }

    function testTransferAdmin() public {
        address newAdmin = address(0x999);
        
        // 非管理员尝试转移
        vm.prank(user1);
        vm.expectRevert("Only admin can transfer admin");
        bigBank.transferAdmin(newAdmin);
        
        // 管理员成功转移
        vm.prank(bigBank.admin());
        bigBank.transferAdmin(newAdmin);
        assertEq(bigBank.admin(), newAdmin);
    }

    function testAdminWithdraw() public {
        // 存款
        vm.prank(user1);
        bigBank.deposit{value: 1 ether}();
        
        // 转移管理员权限
        vm.prank(bigBank.admin());
        bigBank.transferAdmin(address(adminContract));
        
        // 管理员提现
        vm.prank(adminContract.owner());
        adminContract.adminWithdraw(bigBank);
        
        assertEq(address(adminContract).balance, 1 ether);
    }

    function testTopUsersEdgeCases() public {
        // 测试相同金额的存款
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 1 ether}();
        
        // 验证排名
        assertEq(bank.topUsers(0), user1);
        assertEq(bank.topUsers(1), user2);
    }

    // 添加 receive 函数来接收 ETH
    receive() external payable {}
}