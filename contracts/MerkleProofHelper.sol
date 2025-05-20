// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleProofHelper
 * @dev Merkle 树验证辅助库
 * 提供了用于生成和验证 Merkle 树证明的工具函数
 */
library MerkleProofHelper {
    /**
     * @dev 验证 Merkle 树证明
     * @param proof Merkle 树证明路径
     * @param root Merkle 树根节点
     * @param leaf 要验证的叶子节点
     * @return bool 验证是否通过
     * 
     * 使用 OpenZeppelin 的 MerkleProof 库进行验证
     * 验证给定的证明路径是否能够将叶子节点连接到根节点
     */
    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev 计算账户地址对应的叶子节点哈希值
     * @param account 要计算哈希的账户地址
     * @return bytes32 账户地址的哈希值
     * 
     * 将地址进行 keccak256 哈希运算
     * 这个哈希值将作为 Merkle 树的叶子节点
     */
    function getLeaf(address account) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
} 