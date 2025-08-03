// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

// ---------------------------
// Custom Errors
// ---------------------------
error InsufficientSenderTokenBalance();
error FeeTransferFailed();
error NotTrustedBundler();
error NoProceedsToWithdraw();
error WithdrawTransferFailed();

/**
 * @title HinomaruPaymaster (Base Class)
 * @author FickleWolf
 * @notice Generic Paymaster base contract to enable gas payments using any ERC20 token.
 * @dev Designed for extensibility by child contracts like JpycPaymaster, UsdcPaymaster, etc.
 */
abstract contract HinomaruPaymaster is BasePaymaster {
    /**
     * @notice Mapping of trusted Bundler EOA addresses authorized to relay UserOps.
     */
    mapping(address => bool) public trustedBundlers;

    /**
     * @notice ERC20 token used for gas payment (must be set in child contract).
     */
    IERC20 public immutable token;

    /**
     * @notice Fixed token fee per UserOp (in wei).
     */
    uint256 public fee;

    /**
     * @notice Emitted when a new bundler is trusted.
     * @param bundler The address of the trusted bundler.
     */
    event TrustedBundlerAdded(address indexed bundler);

    /**
     * @notice Emitted when a bundler is removed.
     * @param bundler The address of the removed bundler.
     */
    event TrustedBundlerRemoved(address indexed bundler);

    /**
     * @notice Emitted when the fixed fee is updated.
     * @param newFee The new token fee per UserOp.
     */
    event FeeUpdated(uint256 indexed newFee);

    /**
     * @notice Constructor.
     * @param _entryPoint The ERC-4337 EntryPoint address.
     * @param _token The ERC20 token address used for fee payment.
     * @param _initialFee The initial token fee per UserOperation (in wei).
     */
    constructor(
        IEntryPoint _entryPoint,
        IERC20 _token,
        uint256 _initialFee
    ) BasePaymaster(_entryPoint) {
        token = _token;
        fee = _initialFee;
        // Automatically trust the deployer (assumed to be owner)
        trustedBundlers[msg.sender] = true;
    }

    // ---------------------------
    // Trusted Bundler Management
    // ---------------------------

    /**
     * @notice Adds a new trusted bundler.
     * @param bundler The address of the bundler to add.
     */
    function addTrustedBundler(address bundler) external onlyOwner {
        trustedBundlers[bundler] = true;
        emit TrustedBundlerAdded(bundler);
    }

    /**
     * @notice Removes a trusted bundler.
     * @param bundler The address of the bundler to remove.
     */
    function removeTrustedBundler(address bundler) external onlyOwner {
        trustedBundlers[bundler] = false;
        emit TrustedBundlerRemoved(bundler);
    }

    // ---------------------------
    // Fee Configuration
    // ---------------------------

    /**
     * @notice Sets a new fixed fee per UserOp.
     * @param newFee The new token fee amount.
     */
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
        emit FeeUpdated(newFee);
    }

    // ---------------------------
    // Revenue Withdrawal
    // ---------------------------

    /**
     * @notice Withdraws collected token fees to any specified address.
     * @param to The recipient address.
     */
    function claimProceeds(address to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert NoProceedsToWithdraw();
        }

        bool success = token.transfer(to, balance);
        if (!success) {
            revert WithdrawTransferFailed();
        }
    }

    // ---------------------------
    // ERC-4337 Paymaster Hooks
    // ---------------------------

    /**
     * @notice Validates the paymaster UserOperation and checks for sufficient sender balance and trusted bundler.
     * @param userOp The packed user operation.
     * @param _userOpHash The hash of the user operation (unused).
     * @param _maxCost The maximum cost estimation (unused).
     * @return context The encoded sender address to pass to postOp.
     * @return validationData Always returns 0 if valid, otherwise reverts.
     */
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
        // Silence compiler warning about unused variables
        _userOpHash;
        _maxCost;

        if (!trustedBundlers[msg.sender]) {
            revert NotTrustedBundler();
        }

        address sender = userOp.sender;
        if (token.balanceOf(sender) < fee) {
            revert InsufficientSenderTokenBalance();
        }

        return (abi.encode(sender), 0);
    }

    /**
     * @notice Handles post-operation logic, transferring the token fee from sender to this contract.
     * @param _mode The post-operation mode (unused).
     * @param context The context containing the sender address.
     * @param _actualGasCost The actual gas cost (unused).
     * @param _actualUserOpFeePerGas The actual UserOp fee per gas (unused).
     */
    function _postOp(
        PostOpMode _mode,
        bytes calldata context,
        uint256 _actualGasCost,
        uint256 _actualUserOpFeePerGas
    ) internal override {
        // Silence compiler warning about unused variables
        _mode;
        _actualGasCost;
        _actualUserOpFeePerGas;

        address sender = abi.decode(context, (address));
        if (!token.transferFrom(sender, address(this), fee)) {
            revert FeeTransferFailed();
        }
    }
}
