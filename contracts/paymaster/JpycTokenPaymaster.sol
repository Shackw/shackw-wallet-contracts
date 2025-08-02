// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title JpycTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling JPYC token payments for gas fees.
 * @dev Inherits from HinomaruPaymaster and specifies JPYC as the payment token.
 */
contract JpycTokenPaymaster is HinomaruPaymaster {
  /**
   * @notice Constructs a JPYC Paymaster contract.
   * @param entryPoint The address of the ERC-4337 EntryPoint contract.
   * @param jpyc The address of the JPYC ERC20 token contract.
   * @param initialFee The initial fixed JPYC token fee per UserOperation (in wei).
   */
  constructor(
    IEntryPoint entryPoint,
    IERC20 jpyc,
    uint256 initialFee
  ) HinomaruPaymaster(entryPoint, jpyc, initialFee) {}
}
