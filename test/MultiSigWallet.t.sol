// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    uint public constant NUM_CONFIRMATIONS_REQUIRED = 2;

    address public owner1;
    address public owner2;
    address public owner3;
    address public nonOwner;

    function setUp() public {
        // 创建测试账户
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        nonOwner = makeAddr("nonOwner");

        // 设置多签持有人
        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // 部署合约
        wallet = new MultiSigWallet(owners, NUM_CONFIRMATIONS_REQUIRED);

        // 给钱包转入一些 ETH 用于测试
        vm.deal(address(wallet), 10 ether);
    }

    function testConstructor() public {
        assertEq(wallet.getOwners().length, 3);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(nonOwner));
        assertEq(wallet.numConfirmationsRequired(), NUM_CONFIRMATIONS_REQUIRED);
    }

    function testSubmitTransaction() public {
        // 非持有人不能提交交易
        vm.prank(nonOwner);
        vm.expectRevert("not owner");
        wallet.submitTransaction(address(0x123), 1 ether, "");

        // 持有人可以提交交易
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 1 ether, "");

        // 验证交易信息
        (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        ) = wallet.getTransaction(0);

        assertEq(to, address(0x123));
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertFalse(executed);
        assertEq(numConfirmations, 0);
    }

    function testConfirmTransaction() public {
        // 首先提交一个交易
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 1 ether, "");

        // 确认交易
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        // 验证确认数
        (, , , , uint numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 2);
    }

    function testExecuteTransaction() public {
        address recipient = makeAddr("recipient");
        uint amount = 1 ether;

        // 提交交易
        vm.prank(owner1);
        wallet.submitTransaction(recipient, amount, "");

        // 确认交易
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        // 执行交易前记录余额
        uint balanceBefore = address(recipient).balance;

        // 执行交易
        wallet.executeTransaction(0);

        // 验证交易执行结果
        uint balanceAfter = address(recipient).balance;
        assertEq(balanceAfter - balanceBefore, amount);

        // 验证交易状态
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function testRevokeConfirmation() public {
        // 提交交易
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 1 ether, "");

        // 确认交易
        vm.prank(owner1);
        wallet.confirmTransaction(0);

        // 撤销确认
        vm.prank(owner1);
        wallet.revokeConfirmation(0);

        // 验证确认数
        (, , , , uint numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 0);
    }

    receive() external payable {}
} 