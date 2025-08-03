// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title EurcTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling EURC token payments for gas fees.
 * @dev Inherits from HinomaruPaymaster and specifies EURC as the payment token.
 */
contract EurcTokenPaymaster is HinomaruPaymaster {
    /**
     * @notice Constructs a EURC Paymaster contract.
     * @param entryPoint The address of the ERC-4337 EntryPoint contract.
     * @param eurc The address of the EURC ERC20 token contract.
     * @param initialFee The initial fixed EURC token fee per UserOperation (in wei).
     */
    constructor(
        IEntryPoint entryPoint,
        IERC20 eurc,
        uint256 initialFee
    ) HinomaruPaymaster(entryPoint, eurc, initialFee) {}
}
