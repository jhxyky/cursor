// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTMarketplaceV2} from "../src/NFTMarketplaceV2.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeToV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("MARKETPLACE_PROXY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 部署新的实现合约
        NFTMarketplaceV2 newImpl = new NFTMarketplaceV2();

        // 升级代理合约
        ITransparentUpgradeableProxy(proxyAddress).upgradeToAndCall(
            address(newImpl),
            "" // 不需要调用初始化函数
        );

        vm.stopBroadcast();

        console.log("New Implementation:", address(newImpl));
        console.log("Proxy:", proxyAddress);
    }
} 