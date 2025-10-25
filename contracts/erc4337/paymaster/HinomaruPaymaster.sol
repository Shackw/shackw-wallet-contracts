// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

using MessageHashUtils for bytes32;
using ECDSA for bytes32;

/**
 * @title HinomaruWallet
 * @author FickleWolf
 * @notice Sponsor-gas Paymaster for ERC-4337 (AA) that validates user operations via
 *         an off-chain trusted signer and a trusted bundler allowlist.
 */
contract HinomaruWallet is BasePaymaster, ReentrancyGuard {
    // ---------------------------------------------------------------------
    // Constants
    // ---------------------------------------------------------------------

    /**
     * @dev Size of address prefix in paymasterAndData (EntryPoint prepends the Paymaster address).
     */
    uint256 private constant ADDRESS_SIZE = 20;

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------

    /// @notice Thrown when a zero address is provided for trusted signer.
    error TrustedSignerCannotBeZero();

    /// @notice Thrown when the caller is not an allowlisted bundler.
    error NotTrustedBundler();

    /// @notice Thrown when paymasterAndData signature verification fails.
    error InvalidPaymasterSignature();

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------

    /**
     * @notice Emitted when the trusted signer is updated.
     * @param newSigner New EOA address that signs paymaster approvals.
     */
    event TrustedSignerUpdated(address indexed newSigner);

    /**
     * @notice Emitted when a bundler is allowlisted.
     * @param bundler Bundler EOA.
     */
    event TrustedBundlerAdded(address indexed bundler);

    /**
     * @notice Emitted when a bundler is removed from allowlist.
     * @param bundler Bundler EOA.
     */
    event TrustedBundlerRemoved(address indexed bundler);

    // ---------------------------------------------------------------------
    // Storage
    // ---------------------------------------------------------------------

    /**
     * @notice Off-chain signer used to attest (userOpHash, validUntil, validAfter).
     * @dev Must be an EOA managed by the paymaster server.
     */
    address public trustedSigner;

    /**
     * @notice Allowlist of bundlers permitted to relay UserOps via this Paymaster.
     * @dev Key: bundler EOA address → bool.
     */
    mapping(address => bool) public trustedBundlers;

    // ---------------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------------

    /**
     * @notice Deploys the HinomaruWallet Paymaster.
     * @param _entryPoint ERC-4337 EntryPoint address.
     * @param _trustedSigner EOA used by the paymaster server to sign approvals.
     */
    constructor(
        IEntryPoint _entryPoint,
        address _trustedSigner
    ) BasePaymaster(_entryPoint) {
        if (_trustedSigner == address(0)) {
            revert TrustedSignerCannotBeZero();
        }
        trustedSigner = _trustedSigner;

        // Deployer convenience: allowlist the deployer as a bundler by default.
        // You can remove it later if unnecessary.
        trustedBundlers[msg.sender] = true;
        emit TrustedBundlerAdded(msg.sender);
    }

    // ---------------------------------------------------------------------
    // Owner Operations
    // ---------------------------------------------------------------------

    /**
     * @notice Updates the trusted signer EOA.
     * @dev onlyOwner (Ownable2Step from BasePaymaster v0.8).
     * @param newSigner New EOA address; must be non-zero.
     */
    function updateTrustedSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) {
            revert TrustedSignerCannotBeZero();
        }
        trustedSigner = newSigner;
        emit TrustedSignerUpdated(newSigner);
    }

    /**
     * @notice Adds a bundler EOA to the allowlist.
     * @dev onlyOwner.
     * @param bundler Bundler EOA to allow.
     */
    function addTrustedBundler(address bundler) external onlyOwner {
        trustedBundlers[bundler] = true;
        emit TrustedBundlerAdded(bundler);
    }

    /**
     * @notice Removes a bundler EOA from the allowlist.
     * @dev onlyOwner.
     * @param bundler Bundler EOA to remove.
     */
    function removeTrustedBundler(address bundler) external onlyOwner {
        trustedBundlers[bundler] = false;
        emit TrustedBundlerRemoved(bundler);
    }

    /**
     * @notice Read helper for frontends/ops tools.
     * @param bundler Address to test.
     * @return True if the bundler is allowlisted.
     */
    function isTrustedBundler(address bundler) external view returns (bool) {
        return trustedBundlers[bundler];
    }

    // ---------------------------------------------------------------------
    // ERC-4337 Hooks
    // ---------------------------------------------------------------------
    // BasePaymaster (v0.8) requires overriding:
    //   - _validatePaymasterUserOp
    //   - _postOp
    //
    // NOTE:
    //  - This Paymaster does not charge users and does not account gas;
    //    it purely sponsors valid UserOps. Thus, _postOp is intentionally empty.

    /**
     * @inheritdoc BasePaymaster
     *
     * @dev Validation policy:
     *  1. Bundler must be allowlisted: msg.sender ∈ trustedBundlers.
     *  2. paymasterAndData must decode into (validUntil, validAfter, signature).
     *  3. Signature must be from `trustedSigner` over:
     *       toEthSignedMessageHash( keccak256( userOpHash, validUntil, validAfter ) ).
     *  4. Returns packed validationData with (sigFailed=false, validUntil, validAfter).
     *
     * Context:
     *  - Since we do not use postOp, context is returned as empty bytes.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 /* _maxCost */
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        // 1) Bundler allowlist check
        if (!trustedBundlers[tx.origin]) {
            revert NotTrustedBundler();
        }

        // 2) Decode paymasterAndData (skip the 20-byte paymaster address prefix)
        (
            uint48 validUntil,
            uint48 validAfter,
            bytes memory signature
        ) = _decodePaymasterAndData(userOp.paymasterAndData);

        // 3) Signature verification
        _verifySignature(userOpHash, validUntil, validAfter, signature);

        // 4) No postOp context needed; return packed validationData for EPC
        return ("", _packValidationData(false, validUntil, validAfter));
    }

    /**
     * @inheritdoc BasePaymaster
     *
     * @dev No token charging / no accounting. Intentionally empty.
     */
    function _postOp(
        PostOpMode /* mode */,
        bytes calldata /* context */,
        uint256 /* actualGasCost */,
        uint256 /* actualUserOpFeePerGas */
    ) internal override {
        // no-op
    }

    // ---------------------------------------------------------------------
    // Internal Helpers
    // ---------------------------------------------------------------------

    /**
     * @notice Decodes (validUntil, validAfter, signature) from paymasterAndData.
     * @dev paymasterAndData layout:
     *   [0:20)   = address(this)
     *   [20:.. ) = abi.encode(uint48 validUntil, uint48 validAfter, bytes signature)
     * @param paymasterAndData Bytes passed by the userOp to EntryPoint.
     */
    function _decodePaymasterAndData(
        bytes calldata paymasterAndData
    )
        internal
        pure
        returns (uint48 validUntil, uint48 validAfter, bytes memory signature)
    {
        // Defensive: ensure length is at least 20 bytes (address) + minimal head (3*32 for tuple head)
        if (paymasterAndData.length < ADDRESS_SIZE + 3 * 32) {
            // Fallback on a signature failure error to avoid leaking parsing detail.
            revert InvalidPaymasterSignature();
        }
        (validUntil, validAfter, signature) = abi.decode(
            paymasterAndData[ADDRESS_SIZE:],
            (uint48, uint48, bytes)
        );
    }

    /**
     * @notice Verifies ECDSA signature from trustedSigner over (userOpHash, validUntil, validAfter).
     * @param userOpHash Hash computed by EntryPoint for the given UserOp.
     * @param validUntil Expiry (inclusive upper bound).
     * @param validAfter Not-valid-before (lower bound).
     * @param signature ECDSA signature bytes from trustedSigner.
     */
    function _verifySignature(
        bytes32 userOpHash,
        uint48 validUntil,
        uint48 validAfter,
        bytes memory signature
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(userOpHash, validUntil, validAfter)
        ).toEthSignedMessageHash();

        address recovered = digest.recover(signature);
        if (recovered != trustedSigner) {
            revert InvalidPaymasterSignature();
        }
    }
}
