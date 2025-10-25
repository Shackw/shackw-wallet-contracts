// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruTokenPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title EurcTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling EURC token payments for gas fees.
 * @dev Inherits from HinomaruTokenPaymaster and specifies EURC as the payment token.
 */
contract EurcTokenPaymaster is HinomaruTokenPaymaster {
    // Default fee configuration: 1% charge, capped at 50 JPY (≈ 0.29 EURC assuming 18 decimals)
    uint256 private constant DEFAULT_FEE_BPS = 100; // 1%
    uint256 private constant DEFAULT_FEE_CAP = 0.29 * 1e6; // 0.29 EURC (6 decimals)

    /**
     * @notice Constructs a EURC Paymaster contract.
     * @param entryPoint The address of the ERC-4337 EntryPoint contract.
     * @param eurc The address of the EURC ERC20 token contract.
     * @param signer The trusted off-chain signature verifier.
     */
    constructor(
        IEntryPoint entryPoint,
        IERC20 eurc,
        address signer
    )
        HinomaruTokenPaymaster(
            entryPoint,
            eurc,
            signer,
            DEFAULT_FEE_BPS,
            DEFAULT_FEE_CAP
        )
    {}
}
