// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "@account-abstraction/contracts/core/BasePaymaster.sol";

error InsufficientJpycBalance();
error JpycTransferFailed();

/// @title JpycTokenPaymaster
/// @author FickleWolf
/// @notice Paymaster contract that allows users to pay gas fees in JPYC tokens
contract JpycTokenPaymaster is BasePaymaster {
    /// @notice JPYC token contract
    IERC20 public immutable jpyc;

    /// @notice Fixed JPYC fee charged per transaction
    uint256 public feeJpyc = 1e18;

    /// @notice Constructor to set the entry point and JPYC token
    /// @param _entryPoint Address of the EntryPoint contract (ERC-4337)
    /// @param _jpyc Address of the JPYC ERC20 token
    constructor(
        IEntryPoint _entryPoint,
        IERC20 _jpyc
    ) BasePaymaster(_entryPoint) {
        jpyc = _jpyc;
    }

    /// @notice Update the fixed JPYC fee
    /// @param newFeeJpyc The new fee amount in JPYC (in wei)
    function setFee(uint256 newFeeJpyc) external onlyOwner {
        feeJpyc = newFeeJpyc;
    }

    /// @notice Validate if user has sufficient JPYC balance before sponsoring gas
    /// @param userOp The user operation being validated
    /// @param _userOpHash The hash of the user operation (unused)
    /// @param _maxCost The maximum cost of the operation (unused)
    /// @return context Encoded sender address used later in _postOp
    /// @return validationData 0 for valid, non-zero otherwise
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 _userOpHash,
        uint256 _maxCost
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        // silence unused parameter warnings
        _userOpHash;
        _maxCost;

        address sender = userOp.sender;
        if (jpyc.balanceOf(sender) < feeJpyc) {
            revert InsufficientJpycBalance();
        }
        context = abi.encode(sender);
        return (context, 0);
    }

    /// @notice Called after the user operation is executed, charges the JPYC fee
    /// @param _mode The mode of the post-operation (e.g., op succeeded or reverted)
    /// @param context Encoded context containing the sender address
    /// @param _actualGasCost Total gas cost used by the operation
    /// @param _actualUserOpFeePerGas Actual fee per gas charged to the user
    function _postOp(
        PostOpMode _mode,
        bytes calldata context,
        uint256 _actualGasCost,
        uint256 _actualUserOpFeePerGas
    ) internal override {
        // silence unused parameter warnings
        _mode;
        _actualGasCost;
        _actualUserOpFeePerGas;

        address sender = abi.decode(context, (address));
        if (!jpyc.transferFrom(sender, address(this), feeJpyc)) {
            revert JpycTransferFailed();
        }
    }
}
