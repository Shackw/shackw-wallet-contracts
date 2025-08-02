// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HinomaruPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title UsdcTokenPaymaster
 * @author FickleWolf
 * @notice Paymaster contract for enabling USDC token payments for gas fees.
 * @dev Inherits from HinomaruPaymaster and specifies USDC as the payment token.
 */
contract UsdcTokenPaymaster is HinomaruPaymaster {
  /**
   * @notice Constructs a USDC Paymaster contract.
   * @param entryPoint The address of the ERC-4337 EntryPoint contract.
   * @param usdc The address of the USDC ERC20 token contract.
   * @param initialFee The initial fixed USDC token fee per UserOperation (in wei).
   */
  constructor(
    IEntryPoint entryPoint,
    IERC20 usdc,
    uint256 initialFee
  ) HinomaruPaymaster(entryPoint, usdc, initialFee) {}
}
