// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet { 
    string public name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
        address currentOwner;
        assembly {
            // owner 始终在 slot 2
            currentOwner := sload(2)
        }
        require(msg.sender == currentOwner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        assembly {
            // owner 始终存储在 slot 2
            sstore(2, caller())
        }
    } 

    function transferOwernship(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        address currentOwner;
        assembly {
            // owner 始终在 slot 2
            currentOwner := sload(2)
        }
        require(currentOwner != _addr, "New owner is the same as the old owner");
        assembly {
            // owner 始终存储在 slot 2
            sstore(2, _addr)
        }
    }
} 