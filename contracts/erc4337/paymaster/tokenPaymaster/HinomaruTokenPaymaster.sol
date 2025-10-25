// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

using MessageHashUtils for bytes32;
using ECDSA for bytes32;

// ---------------------------
// Custom Errors
// ---------------------------
error TrustedSignerCannotBeZero();
error FeeRateTooHigh();
error NoProceedsToWithdraw();
error WithdrawTransferFailed();
error NotTrustedBundler();
error InvalidSignatureForPaymasterAndData();
error InsufficientSenderTokenBalance();
error InsufficientSenderTokenAllowance();

/**
 * @title HinomaruTokenPaymaster (Base Class)
 * @author FickleWolf
 * @notice Generic Paymaster base contract to enable gas payments using any ERC20 token.
 * @dev Designed for extensibility by child contracts like JpycPaymaster, UsdcPaymaster, etc.
 */
abstract contract HinomaruTokenPaymaster is BasePaymaster, ReentrancyGuard {
    /// @dev Size of the address prefix in `paymasterAndData`. Required to skip the address when decoding.
    /// EntryPoint passes the Paymaster's address (20 bytes) at the beginning of `paymasterAndData`,
    /// so we slice it off before decoding the appended custom data.
    uint256 private constant ADDRESS_SIZE = 20;

    /**
     * @notice Off-chain signer used to authorize valid UserOperations.
     */
    address public trustedSigner;

    /**
     * @notice Mapping of trusted Bundler EOA addresses authorized to relay UserOps.
     */
    mapping(address => bool) public trustedBundlers;

    /**
     * @notice ERC20 token used for gas payment (must be set in child contract).
     */
    IERC20 public immutable token;

    /**
     * @notice Fee rate expressed in basis points. (e.g. 100 = 1%)
     * @dev Used to calculate dynamic fees based on token transfer amounts.
     */
    uint256 public feeBps;

    /**
     * @notice Maximum fee amount that can be charged per UserOperation.
     * @dev Expressed in the token's smallest unit (e.g. 50 * 1e18 for JPYC).
     */
    uint256 public feeCap;

    /**
     * @notice Emitted when the trusted signer address is updated.
     * @param newSigner The new signer address.
     */
    event TrustedSignerUpdated(address indexed newSigner);

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
     * @notice Emitted when the fee rate is updated.
     * @param newFeeBps The new fee rate in basis points.
     */
    event FeeRateUpdated(uint256 indexed newFeeBps);

    /**
     * @notice Emitted when the maximum fee cap is updated.
     * @param newFeeCap The new maximum fee amount in token units.
     */
    event FeeCapUpdated(uint256 indexed newFeeCap);

    /**
     * @notice Emitted when fee collection from sender fails during postOp.
     * @param sender The user address that failed to pay.
     * @param attemptedFee The token amount attempted to be collected.
     */
    event FeeCollectionFailed(
        address indexed sender,
        uint256 indexed attemptedFee
    );

    /**
     * @notice Constructor.
     * @param _entryPoint The ERC-4337 EntryPoint address.
     * @param _token The ERC20 token address used for fee payment.
     * @param _trustedSigner The address used to sign authorized UserOperations.
     * @param _initialFeeBps Initial fee rate in basis points (1% = 100).
     * @param _initialFeeCap Initial maximum fee cap in token units.
     */
    constructor(
        IEntryPoint _entryPoint,
        IERC20 _token,
        address _trustedSigner,
        uint256 _initialFeeBps,
        uint256 _initialFeeCap
    ) BasePaymaster(_entryPoint) {
        token = _token;
        trustedSigner = _trustedSigner;
        trustedBundlers[msg.sender] = true;
        feeBps = _initialFeeBps;
        feeCap = _initialFeeCap;
    }

    // ---------------------------
    // Trusted Signer Management
    // ---------------------------

    /**
     * @notice Updates the trusted off-chain signer used for Paymaster signature verification.
     * @param newSigner The new trusted signer address.
     */
    function updateTrustedSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) {
            revert TrustedSignerCannotBeZero();
        }
        trustedSigner = newSigner;
        emit TrustedSignerUpdated(newSigner);
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
     * @notice Calculates the fee to charge based on the transfer amount.
     * @dev Returns the smaller of (amount * feeBps / 10_000) or feeCap.
     * @param amount The token transfer amount in smallest unit (e.g. wei).
     * @return feeAmount The computed fee amount.
     */
    function getTransferFee(
        uint256 amount
    ) public view virtual returns (uint256) {
        uint256 fee = (amount * feeBps) / 10_000;
        return fee > feeCap ? feeCap : fee;
    }

    /**
     * @notice Updates the fee rate in basis points.
     * @dev Reverts if the new rate exceeds 10,000 (100%).
     * @param newFeeBps The new fee rate in basis points.
     */
    function updateFeeRate(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > 10_000) {
            revert FeeRateTooHigh();
        }
        feeBps = newFeeBps;
        emit FeeRateUpdated(newFeeBps);
    }

    /**
     * @notice Updates the maximum fee cap.
     * @param newFeeCap The new maximum fee amount in token units.
     */
    function updateFeeCap(uint256 newFeeCap) external onlyOwner {
        feeCap = newFeeCap;
        emit FeeCapUpdated(newFeeCap);
    }

    // ---------------------------
    // Revenue Withdrawal
    // ---------------------------

    /**
     * @notice Withdraws collected token fees to any specified address.
     * @param to The recipient address.
     */
    function claimProceeds(address to) external onlyOwner nonReentrant {
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
     * @param userOpHash The hash of the user operation.
     * @param _maxCost The maximum cost estimation (unused).
     * @return context The encoded sender address to pass to postOp.
     * @return validationData Always returns 0 if valid, otherwise reverts.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 _maxCost
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        // Silence compiler warning about unused variables
        _maxCost;

        address sender = userOp.sender;
        bytes calldata paymasterAndData = userOp.paymasterAndData;

        // Step 1: Check if the bundler is trusted
        _requireTrustedBundler();

        // Step 2: Decode paymaster-specific fields
        (
            uint48 validUntil,
            uint48 validAfter,
            uint256 amount,
            bytes memory signature
        ) = _decodePaymasterAndData(paymasterAndData);

        // Step 3: Recover signer and validate signature
        _verifySignature(userOpHash, validUntil, validAfter, amount, signature);

        // Step 4: Check token balance and allowance
        _checkSenderFeeSufficiency(sender, amount);

        // Step 5: Return context and validationData for EntryPoint
        return (
            abi.encode(sender, amount),
            _packValidationData(false, validUntil, validAfter)
        );
    }

    /**
     * @notice Reverts if the msg.sender is not a trusted bundler.
     */
    function _requireTrustedBundler() internal view {
        if (!trustedBundlers[msg.sender]) {
            revert NotTrustedBundler();
        }
    }

    /**
     * @notice Decodes the custom fields in `paymasterAndData`.
     * @param paymasterAndData The calldata including extra paymaster fields.
     * @return validUntil Expiration time.
     * @return validAfter Start time.
     * @return amount Amount to transfer.
     * @return signature Off-chain signature for verification.
     */
    function _decodePaymasterAndData(
        bytes calldata paymasterAndData
    )
        internal
        pure
        returns (
            uint48 validUntil,
            uint48 validAfter,
            uint256 amount,
            bytes memory signature
        )
    {
        return
            abi.decode(
                paymasterAndData[ADDRESS_SIZE:],
                (uint48, uint48, uint256, bytes)
            );
    }

    /**
     * @notice Reconstructs the signed message and verifies it matches the trusted signer.
     * @param userOpHash The hash of the user operation.
     * @param validUntil Signature expiration.
     * @param validAfter Signature valid from.
     * @param amount Amount to be validated.
     * @param signature Signature bytes from the user.
     */
    function _verifySignature(
        bytes32 userOpHash,
        uint48 validUntil,
        uint48 validAfter,
        uint256 amount,
        bytes memory signature
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(userOpHash, validUntil, validAfter, amount)
        );
        address recovered = hash.toEthSignedMessageHash().recover(signature);
        if (recovered != trustedSigner) {
            revert InvalidSignatureForPaymasterAndData();
        }
    }

    /**
     * @notice Checks if the sender has enough balance and allowance to pay the calculated fee.
     * @param sender The address of the user.
     * @param amount The token amount to calculate fee from.
     */
    function _checkSenderFeeSufficiency(
        address sender,
        uint256 amount
    ) internal view {
        uint256 fee = getTransferFee(amount);
        if (token.balanceOf(sender) < fee) {
            revert InsufficientSenderTokenBalance();
        }
        if (token.allowance(sender, address(this)) < fee) {
            revert InsufficientSenderTokenAllowance();
        }
    }

    /**
     * @notice Handles post-operation logic, transferring the token fee from sender to this contract.
     * @param mode The post-operation mode.
     * @param context The context containing the sender address.
     * @param _actualGasCost The actual gas cost (unused).
     * @param _actualUserOpFeePerGas The actual UserOp fee per gas (unused).
     */
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 _actualGasCost,
        uint256 _actualUserOpFeePerGas
    ) internal override {
        // Silence compiler warning about unused variables
        _actualGasCost;
        _actualUserOpFeePerGas;

        (address sender, uint256 amount) = abi.decode(
            context,
            (address, uint256)
        );
        uint256 feeToCollect = getTransferFee(amount);

        if (mode != PostOpMode.postOpReverted) {
            bool success = token.transferFrom(
                sender,
                address(this),
                feeToCollect
            );
            if (!success) {
                emit FeeCollectionFailed(sender, feeToCollect);
            }
        }
    }
}
