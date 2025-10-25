// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @notice Minimal Registry interface used by the delegate.
 */
interface IRegistry {
    /**
     * @notice Returns the global sponsor EOA authorized to call `execute`.
     */
    function getSponsor() external view returns (address);

    /**
     * @notice Consumes the caller's monotonic nonce. Under EIP-7702 the caller is the EOA.
     * @param nonce The expected next nonce for the EOA.
     */
    function useNonce(uint256 nonce) external;
}

/**
 * @title HinomaruDelegate
 * @author FickleWolf
 * @notice Delegate code to be loaded into an EOA via EIP-7702.
 *         - The sponsor is resolved from the Registry on every call.
 *         - Nonce is consumed via the Registry at the start of execution.
 *         - The Registry address is immutable and readable under 7702.
 *         - Reverts on the first failing sub-call (no partial success).
 *         - Emits a minimal success event for off-chain correlation.
 */
contract HinomaruDelegate {
    /**
     * @notice Sub-call specification.
     * @param to Target address.
     * @param value ETH value forwarded.
     * @param data Calldata for the target.
     */
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    /**
     * @notice Immutable Registry reference.
     */
    IRegistry public immutable registry;

    /**
     * @notice Emitted only on successful execution.
     * @param callHash Off-chain intent hash confirmed on-chain.
     * @param sponsor  The sponsor EOA (msg.sender).
     * @param eoa      The delegated EOA (address(this) under 7702).
     */
    event Executed(
        bytes32 indexed callHash,
        address indexed sponsor,
        address indexed eoa
    );

    /**
     * @notice Reverts when the caller is not the resolved sponsor.
     */
    error OnlySponsor();

    /**
     * @notice Reverts when msg.value does not equal the sum of sub-call values.
     */
    error BadMsgValue();

    /**
     * @notice Reverts when the provided hash does not match the on-chain recomputation.
     * @param expected Expected hash computed on-chain.
     * @param got      Provided hash.
     */
    error InvalidCallHash(bytes32 expected, bytes32 got);

    /**
     * @notice Reverts when the current timestamp exceeds the provided expiration.
     * @param nowTs         The current block timestamp.
     * @param expiresAtSec  The expiration timestamp (inclusive upper bound).
     */
    error Expired(uint256 nowTs, uint256 expiresAtSec);

    /**
     * @notice Reverts when a sub-call fails (no inline assembly; includes raw revert data).
     * @param index      Index of the failed sub-call.
     * @param to         Target address of the failed sub-call.
     * @param revertData Raw revert bytes returned by the target.
     */
    error SubcallFailed(uint256 index, address to, bytes revertData);

    /**
     * @notice Sets the immutable Registry address.
     * @param registry_ Address of the Registry contract.
     */
    constructor(address registry_) {
        registry = IRegistry(registry_);
    }

    /**
     * @notice Executes a batch of calls as the EOA and emits a success event.
     * @dev    Always reverts on the first failing sub-call (no partial success).
     *         Off-chain must compute:
     *           callHash = keccak256(abi.encode(chainId, eoa, calls, expiresAtSec, nonce))
     *         where:
     *           - chainId = current chain id
     *           - eoa     = delegated account (same as address(this) under 7702)
     *           - calls   = the exact tuple[] payload (to, value, data)
     *           - expiresAtSec = unix timestamp (tx must satisfy block.timestamp <= expiresAtSec)
     *           - nonce   = Registry.nextNonce(eoa) at the time of quoting
     * @param  calls        Array of sub-calls (to, value, data).
     * @param  nonce        Monotonic nonce obtained from the Registry.
     * @param  expiresAtSec Expiration timestamp (unix seconds).
     * @param  callHash     Off-chain computed hash to be verified and emitted.
     */
    function execute(
        Call[] calldata calls,
        uint256 nonce,
        uint256 expiresAtSec,
        bytes32 callHash
    ) external payable {
        if (msg.sender != registry.getSponsor()) revert OnlySponsor();

        uint256 nowTs = block.timestamp;
        if (nowTs > expiresAtSec) revert Expired(nowTs, expiresAtSec);

        bytes32 expected = keccak256(
            abi.encode(block.chainid, address(this), calls, expiresAtSec, nonce)
        );
        if (expected != callHash) revert InvalidCallHash(expected, callHash);

        registry.useNonce(nonce);

        uint256 need;
        unchecked {
            for (uint256 i; i < calls.length; ++i) {
                need += calls[i].value;
            }
        }
        if (msg.value != need) revert BadMsgValue();

        for (uint256 i = 0; i < calls.length; ++i) {
            Call calldata c = calls[i];
            (bool ok, bytes memory ret) = c.to.call{value: c.value}(c.data);
            if (!ok) {
                revert SubcallFailed(i, c.to, ret);
            }
        }

        emit Executed(callHash, msg.sender, address(this));
    }

    /**
     * @notice Accepts ETH pre-funding from relayers.
     */
    receive() external payable {}
}
