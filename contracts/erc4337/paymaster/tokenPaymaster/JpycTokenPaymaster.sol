// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruTokenPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title JpycTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling JPYC token payments for gas fees.
 * @dev Inherits from HinomaruTokenPaymaster and specifies JPYC as the payment token.
 */
contract JpycTokenPaymaster is HinomaruTokenPaymaster {
    // Default values: 1% fee with 50円 cap
    uint256 private constant DEFAULT_FEE_BPS = 100; // 1%
    uint256 private constant DEFAULT_FEE_CAP = 50 * 1e18; // 50 JPYC (assuming 18 decimals)

    /**
     * @notice Constructs a JPYC Paymaster contract.
     * @param entryPoint The address of the ERC-4337 EntryPoint contract.
     * @param jpyc The address of the JPYC ERC20 token contract.
     * @param trustedSigner The off-chain signer that authorizes UserOperations.
     */
    constructor(
        IEntryPoint entryPoint,
        IERC20 jpyc,
        address trustedSigner
    )
        HinomaruTokenPaymaster(
            entryPoint,
            jpyc,
            trustedSigner,
            DEFAULT_FEE_BPS,
            DEFAULT_FEE_CAP
        )
    {}
}
