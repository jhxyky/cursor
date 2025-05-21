// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarketplaceV1} from "../src/NFTMarketplaceV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // 部署 NFT 合约
        MyNFT nftImpl = new MyNFT();
        bytes memory nftData = abi.encodeWithSelector(
            MyNFT.initialize.selector,
            deployerAddress // initialOwner
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImpl),
            nftData
        );
        MyNFT nft = MyNFT(address(nftProxy));

        // 部署市场合约
        NFTMarketplaceV1 marketplaceImpl = new NFTMarketplaceV1();
        bytes memory marketplaceData = abi.encodeWithSelector(
            NFTMarketplaceV1.initialize.selector,
            deployerAddress, // initialOwner
            250, // initialFee (2.5%)
            deployerAddress // initialFeeReceiver
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(
            address(marketplaceImpl),
            marketplaceData
        );

        vm.stopBroadcast();

        console.log("NFT Implementation:", address(nftImpl));
        console.log("NFT Proxy:", address(nftProxy));
        console.log("Marketplace Implementation:", address(marketplaceImpl));
        console.log("Marketplace Proxy:", address(marketplaceProxy));
    }
} 