// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast(); // 开始广播（用你的钱包私钥）
        new MyToken("MyToken", "MTK"); // 部署合约，传入名字和符号
        vm.stopBroadcast(); // 结束广播
    }
}