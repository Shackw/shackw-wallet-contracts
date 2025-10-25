// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruTokenPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title UsdcTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling USDC token payments for gas fees.
 * @dev Inherits from HinomaruTokenPaymaster and specifies USDC as the payment token.
 */
contract UsdcTokenPaymaster is HinomaruTokenPaymaster {
    // Default fee configuration: 1% charge, capped at 50 JPY (≈ 0.32 USDC)
    uint256 private constant DEFAULT_FEE_BPS = 100; // 1%
    uint256 private constant DEFAULT_FEE_CAP = 0.32 * 1e6; // 0.32 USDC (6 decimals)

    /**
     * @notice Constructs a USDC Paymaster contract.
     * @param entryPoint The address of the ERC-4337 EntryPoint contract.
     * @param usdc The address of the USDC ERC20 token contract.
     * @param trustedSigner The off-chain signer used for validation.
     */
    constructor(
        IEntryPoint entryPoint,
        IERC20 usdc,
        address trustedSigner
    )
        HinomaruTokenPaymaster(
            entryPoint,
            usdc,
            trustedSigner,
            DEFAULT_FEE_BPS,
            DEFAULT_FEE_CAP
        )
    {}
}
