// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@account-abstraction/contracts/accounts/SimpleAccount.sol";

// ---------------------------
// Custom Errors
// ---------------------------
error NotAllowedPaymaster();

/**
 * @title SmartAccount
 * @author FickleWolf
 * @notice A custom ERC-4337-compatible account contract with Paymaster approval and EIP-1271 support.
 * @dev Inherits from SimpleAccount and extends with Paymaster whitelisting and EIP-1271 signature validation.
 */
contract SmartAccount is SimpleAccount {
    /**
     * @notice Mapping of whitelisted Paymaster addresses.
     * @dev Used to restrict which Paymasters this account will interact with via token approvals.
     */
    mapping(address => bool) public allowedPaymasters;

    /**
     * @notice Emitted when a token approval is granted to a Paymaster.
     * @param token The ERC-20 token approved.
     * @param paymaster The Paymaster contract receiving the approval.
     * @param amount The approved token amount.
     */
    event PaymasterApproved(
        address indexed token,
        address indexed paymaster,
        uint256 indexed amount
    );

    /**
     * @notice Initializes the SmartAccount with the EntryPoint.
     * @param entryPoint The ERC-4337 EntryPoint contract.
     */
    constructor(IEntryPoint entryPoint) SimpleAccount(entryPoint) {}

    /**
     * @notice Initializes the SmartAccount with the owner and list of allowed Paymasters.
     * @dev Called only once post-deployment via proxy. This must be used instead of the constructor.
     * @param anOwner The EOA that owns this SmartAccount.
     * @param _allowedPaymasters List of trusted Paymaster addresses to whitelist.
     */
    function initialize(
        address anOwner,
        address[] memory _allowedPaymasters
    ) public initializer {
        for (uint256 i = 0; i < _allowedPaymasters.length; ++i) {
            allowedPaymasters[_allowedPaymasters[i]] = true;
        }
        super.initialize(anOwner);
    }

    /**
     * @notice Approves a whitelisted Paymaster to pull a specified ERC-20 token amount.
     * @dev Fails if the Paymaster is not in the allowed list.
     * @param token The ERC-20 token to approve.
     * @param paymaster The Paymaster address to approve.
     * @param amount The amount of tokens to approve.
     */
    function approvePaymaster(
        address token,
        address paymaster,
        uint256 amount
    ) public onlyOwner {
        if (!allowedPaymasters[paymaster]) {
            revert NotAllowedPaymaster();
        }
        IERC20(token).approve(paymaster, 0);
        IERC20(token).approve(paymaster, amount);
        emit PaymasterApproved(token, paymaster, amount);
    }

    /**
     * @notice EIP-1271 signature validation for off-chain verifiers (e.g. dApps).
     * @dev Used to prove ownership of this SmartAccount via signature recovery.
     * @param hash The message hash that was signed.
     * @param signature The ECDSA signature.
     * @return magicValue 0x1626ba7e if signature is valid, 0x00000000 otherwise.
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) public view returns (bytes4 magicValue) {
        if (owner == ECDSA.recover(hash, signature)) {
            return 0x1626ba7e; // EIP-1271 magic value
        } else {
            return 0x00000000;
        }
    }
}
