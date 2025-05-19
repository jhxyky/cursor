// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet { 
    string public name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
        address currentOwner;
        assembly {
            // 从 slot 3 读取 owner 地址
            currentOwner := sload(3)
        }
        require(msg.sender == currentOwner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        assembly {
            // 将 msg.sender 存储到 slot 3
            sstore(3, caller())
        }
    } 

    function transferOwernship(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        
        address currentOwner;
        assembly {
            // 从 slot 3 读取当前 owner
            currentOwner := sload(3)
        }
        require(currentOwner != _addr, "New owner is the same as the old owner");
        
        assembly {
            // 将新 owner 地址存储到 slot 3
            sstore(3, _addr)
        }
    }
} 