// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IPermit2
 * @dev Uniswap的Permit2授权接口
 * @notice 这是一个简化版的接口，只包含我们需要的方法
 */
interface IPermit2 {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    // 使用签名授权并执行转账
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
} 