// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/NFTMarket.sol";

contract DeployNFTMarket is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarket nftMarket = new NFTMarket();

        vm.stopBroadcast();
    }
} 