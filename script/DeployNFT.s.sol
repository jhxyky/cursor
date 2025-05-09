// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";

contract DeployNFT is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        MyNFT nft = new MyNFT();
        
        // 铸造一个 NFT 给部署者
        nft.mint(deployerAddress);

        vm.stopBroadcast();

        console.log("NFT contract deployed at:", address(nft));
        console.log("NFT minted to:", deployerAddress);
    }
} 