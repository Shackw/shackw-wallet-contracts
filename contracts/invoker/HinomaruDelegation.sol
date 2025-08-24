// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title HinomaruDelegation
 * @author FickleWolf
 * @notice Stateless invoker intended to be temporarily loaded into an EOA via EIP-7702.
 *         While loaded, `address(this)` equals the EOA and can perform arbitrary calls.
 * @dev    No storage writes. Signature/nonce checks are handled by the 7702 transaction layer.
 */
contract HinomaruDelegation is ReentrancyGuard {
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

    /** @notice Thrown when msg.value does not equal the sum of call values. */
    error BadMsgValue();

    /**
     * @notice Thrown when a pure-ETH transfer (no data) fails and revertOnFail is true.
     * @param index Index of the failed sub-call in the batch.
     * @param to    Target address of the failed transfer.
     */
    error EthTransferFailed(uint256 index, address to);

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
     * @notice Execute a batch of calls as the EOA.
     * @dev    Enforces strict ETH accounting and uses ReentrancyGuard.
     *         For sub-calls with data:
     *           - when revertOnFail=true, bubbles revert reasons via Address.functionCallWithValue;
     *           - when false, uses a low-level call to continue on failures.
     *         For pure ETH transfers (no data), EOAs are allowed.
     * @param  calls        Array of (to, value, data).
     * @param  revertOnFail If true, revert on the first failed sub-call.
     * @return results      Return data for each sub-call (empty for pure ETH transfers).
     */
    function execute(
        Call[] calldata calls,
        bool revertOnFail
    ) external payable nonReentrant returns (bytes[] memory results) {
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
                (ok, ) = c.to.call{value: c.value}("");
                if (!ok && revertOnFail) revert EthTransferFailed(i, c.to);
                ret = "";
            } else {
                if (revertOnFail) {
                    ret = Address.functionCallWithValue(c.to, c.data, c.value);
                    ok = true;
                } else {
                    (ok, ret) = c.to.call{value: c.value}(c.data);
                }
            }

            emit CallResult(i, c.to, c.value, ok, ret);
            results[i] = ret;
        }
    }

    /**
     * @notice Execute a single call as the EOA (slightly cheaper).
     * @param  c            Call to perform.
     * @param  revertOnFail If true, revert on failure.
     * @return ret          Raw return bytes (empty for pure ETH transfers).
     */
    function executeSingle(
        Call calldata c,
        bool revertOnFail
    ) external payable nonReentrant returns (bytes memory ret) {
        if (msg.value != c.value) revert BadMsgValue();

        if (c.data.length == 0) {
            (bool ok, ) = c.to.call{value: c.value}("");
            if (!ok && revertOnFail) revert EthTransferFailed(0, c.to);
            emit CallResult(0, c.to, c.value, ok, "");
            return "";
        }

        if (revertOnFail) {
            ret = Address.functionCallWithValue(c.to, c.data, c.value);
            emit CallResult(0, c.to, c.value, true, ret);
            return ret;
        } else {
            (bool ok, bytes memory r) = c.to.call{value: c.value}(c.data);
            emit CallResult(0, c.to, c.value, ok, r);
            return r;
        }
    }

    /** @notice Accept ETH pre-funding from relayers. */
    receive() external payable {}
}
