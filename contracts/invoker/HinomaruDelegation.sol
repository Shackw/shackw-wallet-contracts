// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title HinomaruDelegation
 * @author FickleWolf
 * @notice Invoker intended to be temporarily loaded into an EOA via EIP-7702.
 *         While loaded, `address(this)` equals the EOA and can perform arbitrary calls.
 * @dev    Minimal storage writes:
 *         - `sponsor` (owner-updatable)
 *         - `used[callHash]` to enforce single-use semantics (replay protection).
 */
contract HinomaruDelegation is ReentrancyGuard, Ownable {
    /**
     * @notice Single call specification.
     * @param to    Target address.
     * @param value ETH value forwarded with the call.
     * @param data  Calldata for the target.
     */
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    /** @notice Designated sponsor (EOA) allowed to invoke `execute`. */
    address public sponsor;

    /** @notice Replay-protection: consumed call hashes. */
    mapping(bytes32 => bool) public used;

    /** @notice Thrown when msg.value does not equal the sum of call values. */
    error BadMsgValue();

    /**
     * @notice Thrown when a pure-ETH transfer (no data) fails and revertOnFail is true.
     * @param index Index of the failed sub-call in the batch.
     * @param to    Target address of the failed transfer.
     */
    error EthTransferFailed(uint256 index, address to);

    /** @notice Thrown when a non-sponsor tries to invoke restricted entrypoints. */
    error OnlySponsor();

    /**
     * @notice Thrown when a callHash has already been consumed.
     * @param callHash The already-used call hash.
     */
    error AlreadyUsed(bytes32 callHash);

    /** @notice Thrown when setting sponsor to the zero address. */
    error SponsorZeroAddress();

    /**
     * @notice Thrown when setting sponsor to the current value.
     * @param current   Current sponsor.
     * @param candidate New sponsor candidate.
     */
    error SponsorUnchanged(address current, address candidate);

    /**
     * @notice Emitted once per sub-call.
     * @param index      Index in the batch.
     * @param to         Target address.
     * @param value      ETH value forwarded.
     * @param success    Whether the sub-call succeeded.
     * @param returnData Raw return bytes from the sub-call.
     */
    event CallResult(
        uint256 indexed index,
        address indexed to,
        uint256 value,
        bool success,
        bytes returnData
    );

    /**
     * @notice Emitted when a callHash is consumed to prevent replays.
     * @param callHash The consumed call hash.
     */
    event CallHashConsumed(bytes32 indexed callHash);

    /**
     * @notice Emitted when the sponsor EOA is updated by the owner.
     * @param previousSponsor Previous sponsor address.
     * @param newSponsor      New sponsor address.
     */
    event SponsorUpdated(
        address indexed previousSponsor,
        address indexed newSponsor
    );

    /**
     * @notice Restrict function to the configured sponsor EOA.
     */
    modifier onlySponsor() {
        if (msg.sender != sponsor) revert OnlySponsor();
        _;
    }

    /**
     * @param _sponsor      The only EOA allowed to trigger execution.
     * @param initialOwner  Contract owner (can update sponsor).
     */
    constructor(address _sponsor, address initialOwner) Ownable(initialOwner) {
        if (_sponsor == address(0)) revert SponsorZeroAddress();
        sponsor = _sponsor;
    }

    /**
     * @notice Execute a batch of calls as the EOA.
     * @dev    Enforces strict ETH accounting and uses ReentrancyGuard.
     *         Replay-protection: `callHash` must be unused and will be marked used.
     *         For sub-calls with data:
     *           - when revertOnFail=true, bubbles revert reasons via Address.functionCallWithValue;
     *           - when false, uses a low-level call to continue on failures.
     *         For pure ETH transfers (no data), EOAs are allowed.
     * @param  calls        Array of (to, value, data).
     * @param  revertOnFail If true, revert on the first failed sub-call.
     * @param  callHash     Off-chain agreed hash for this execution intent (replay key).
     * @return results      Return data for each sub-call (empty for pure ETH transfers).
     */
    function execute(
        Call[] calldata calls,
        bool revertOnFail,
        bytes32 callHash
    )
        external
        payable
        nonReentrant
        onlySponsor
        returns (bytes[] memory results)
    {
        // Replay-protection
        if (used[callHash]) revert AlreadyUsed(callHash);
        used[callHash] = true;
        emit CallHashConsumed(callHash);

        // Strict ETH accounting
        uint256 need;
        unchecked {
            for (uint256 i; i < calls.length; i++) {
                need += calls[i].value;
            }
        }
        if (msg.value != need) revert BadMsgValue();

        uint256 len = calls.length;
        results = new bytes[](len);

        for (uint256 i = 0; i < len; i++) {
            Call calldata c = calls[i];

            bool ok;
            bytes memory ret;

            if (c.data.length == 0) {
                // Pure ETH transfer (no data)
                (ok, ) = c.to.call{value: c.value}("");
                if (!ok && revertOnFail) revert EthTransferFailed(i, c.to);
                ret = "";
            } else {
                if (revertOnFail) {
                    // Bubble revert reasons on failure
                    ret = Address.functionCallWithValue(c.to, c.data, c.value);
                    ok = true;
                } else {
                    // Continue on failure
                    (ok, ret) = c.to.call{value: c.value}(c.data);
                }
            }

            emit CallResult(i, c.to, c.value, ok, ret);
            results[i] = ret;
        }
    }

    /**
     * @notice Update the sponsor EOA allowed to invoke `execute`.
     * @dev    Only callable by the contract owner.
     * @param  newSponsor New sponsor EOA.
     */
    function setSponsor(address newSponsor) external onlyOwner {
        if (newSponsor == address(0)) revert SponsorZeroAddress();
        address prev = sponsor;
        if (newSponsor == prev) revert SponsorUnchanged(prev, newSponsor);
        sponsor = newSponsor;
        emit SponsorUpdated(prev, newSponsor);
    }

    /** @notice Accept ETH pre-funding from relayers. */
    receive() external payable {}
}
