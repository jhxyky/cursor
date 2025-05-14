// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPermit2 {
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
    
    // 记录被使用过的nonce，防止重放攻击
    mapping(address => mapping(uint256 => bool)) public usedNonces;
    
    // 用于测试的有效签名
    bytes public validSignature = new bytes(65);
    
    // 设置有效签名，供测试使用
    function setValidSignature(bytes memory _signature) external {
        validSignature = _signature;
    }

    // 简化版的permitTransferFrom，仅用于测试
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        // 检查基本条件
        require(block.timestamp <= permit.deadline, "Signature expired");
        require(!usedNonces[owner][permit.nonce], "Nonce already used");
        require(transferDetails.requestedAmount <= permit.permitted.amount, "Amount exceeds permitted");
        
        // 这里应该是验证签名的代码，但为了测试简单起见，我们只验证签名长度
        require(signature.length == validSignature.length, "Invalid signature length");
        
        // 标记nonce为已使用
        usedNonces[owner][permit.nonce] = true;
        
        // 执行转账
        IERC20(permit.permitted.token).transferFrom(
            owner, 
            transferDetails.to, 
            transferDetails.requestedAmount
        );
    }
} 