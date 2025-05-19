// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    constructor() ERC721("Test NFT", "TNFT") Ownable(msg.sender) {}
    
    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
} 