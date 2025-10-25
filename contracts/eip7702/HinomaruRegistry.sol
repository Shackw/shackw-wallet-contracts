// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title HinomaruRegistry
 * @author FickleWolf
 * @notice Central registry for a global sponsor and per-EOA nonces.
 *         - All EOAs share the same sponsor (no per-EOA override).
 *         - Each EOA maintains a monotonic nextNonce consumed by the EOA.
 */
contract HinomaruRegistry is Ownable {
    /**
     * @notice Global sponsor used for all EOAs.
     */
    address private _sponsor;

    /**
     * @notice Per-EOA monotonic nonce (next expected value).
     */
    mapping(address => uint256) private _nextNonce;

    /**
     * @notice Reverts when setting the sponsor to the zero address.
     */
    error SponsorZeroAddress();

    /**
     * @notice Reverts when the provided nonce does not match the expected value.
     * @param expected The expected next nonce.
     * @param got The provided nonce.
     */
    error BadNonce(uint256 expected, uint256 got);

    /**
     * @notice Emitted when the global sponsor is updated.
     * @param sponsor The new sponsor address.
     */
    event SponsorUpdated(address indexed sponsor);

    /**
     * @notice Initializes the registry owner and the global sponsor.
     * @param initialOwner The owner of the registry.
     * @param sponsor_ The initial global sponsor.
     */
    constructor(address initialOwner, address sponsor_) Ownable(initialOwner) {
        if (sponsor_ == address(0)) revert SponsorZeroAddress();
        _sponsor = sponsor_;
        emit SponsorUpdated(sponsor_);
    }

    /**
     * @notice Sets the global sponsor used for all EOAs.
     * @param sponsor The new sponsor address.
     */
    function setSponsor(address sponsor) external onlyOwner {
        if (sponsor == address(0)) revert SponsorZeroAddress();
        _sponsor = sponsor;
        emit SponsorUpdated(sponsor);
    }

    /**
     * @notice Returns the global sponsor.
     * @dev Kept signature compatible with delegate calls that pass an EOA.
     */
    function getSponsor() external view returns (address) {
        return _sponsor;
    }

    /**
     * @notice Returns the next expected nonce for an EOA.
     * @param eoa The EOA address.
     */
    function nextNonce(address eoa) external view returns (uint256) {
        return _nextNonce[eoa];
    }

    /**
     * @notice Consumes the caller's nonce. Under EIP-7702 the caller is the EOA.
     * @param nonce The nonce to consume (must equal the expected next nonce).
     */
    function useNonce(uint256 nonce) external {
        uint256 expected = _nextNonce[msg.sender];
        if (nonce != expected) revert BadNonce(expected, nonce);
        unchecked {
            _nextNonce[msg.sender] = expected + 1;
        }
    }
}
