// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/esRNT.sol";

contract DeployEsRNT is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(privateKey);
        
        esRNT token = new esRNT();
        
        console.log("esRNT deployed at:", address(token));
        
        vm.stopBroadcast();
    }
} 