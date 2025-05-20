// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleNFT is ERC721, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("MerkleNFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _mint(to, newTokenId);
        return newTokenId;
    }

    function batchMint(address to, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds++;
            uint256 newTokenId = _tokenIds;
            _mint(to, newTokenId);
        }
    }
} 