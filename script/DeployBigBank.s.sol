// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Bank.sol";

contract DeployBigBank is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署 BigBank 合约
        BigBank bigBank = new BigBank();

        vm.stopBroadcast();
    }
} 