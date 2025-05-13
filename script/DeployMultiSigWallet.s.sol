// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployMultiSigWallet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 创建多签持有人数组
        address[] memory owners = new address[](3);
        owners[0] = 0x353a4F1a2bD8Ed73305dfB8FBD998271465bf367; // 您的地址
        owners[1] = 0x1416Dc32Cd8acee08D35e6FCb5f19D24Da44cEa8; // 第二个多签人地址
        owners[2] = 0x68260850c53f4fa12BD713Cb558DFf7cf9eCaD2e; // 第三个多签人地址

        // 部署多签钱包，设置2/3的门槛
        MultiSigWallet multiSig = new MultiSigWallet(owners, 2);

        vm.stopBroadcast();
    }
} 