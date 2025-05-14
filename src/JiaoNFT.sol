// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title JiaoNFT
 * @dev ERC721 NFT合约
 */
contract JiaoNFT is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    constructor() ERC721("JiaoNFT", "JNFT") Ownable(msg.sender) {
        _baseTokenURI = "";
    }

    /**
     * @dev 铸造NFT
     * @param to 接收者地址
     * @return 铸造的NFT的tokenId
     */
    function mint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev 批量铸造NFT
     * @param to 接收者地址
     * @param amount 铸造数量
     */
    function mintBatch(address to, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            mint(to);
        }
    }

    /**
     * @dev 设置基本URI
     * @param baseURI 新的基本URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev 重写_baseURI函数
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
} 