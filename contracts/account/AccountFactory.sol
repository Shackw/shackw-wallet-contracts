// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@account-abstraction/contracts/interfaces/ISenderCreator.sol";
import "./SmartAccount.sol";

// ---------------------------
// Custom Errors
// ---------------------------
error OnlySenderCreatorAllowed();

/**
 * @title AccountFactory
 * @author FickleWolf
 * @notice Factory contract for deploying ERC-4337-compatible SmartAccounts using CREATE2.
 * @dev Only the EntryPoint's `senderCreator()` is allowed to deploy accounts.
 */
contract AccountFactory {
    /**
     * @notice The base SmartAccount implementation contract.
     */
    SmartAccount public immutable accountImplementation;

    /**
     * @notice The EntryPoint's senderCreator used to validate deployment permission.
     */
    ISenderCreator public immutable senderCreator;

    /**
     * @notice List of trusted paymasters to be whitelisted in each deployed SmartAccount.
     */
    address[] public allowedPaymasters;

    /**
     * @notice Emitted when a new SmartAccount is deployed.
     * @param smartAccount The address of the newly deployed SmartAccount.
     * @param owner The EOA designated as the owner of the account.
     * @param salt The CREATE2 salt used.
     */
    event AccountCreated(
        address indexed smartAccount,
        address indexed owner,
        uint256 indexed salt
    );

    /**
     * @notice Constructs the AccountFactory contract, deploying the SmartAccount implementation and setting the trusted paymasters.
     * @param _entryPoint The ERC-4337 EntryPoint address.
     * @param _allowedPaymasters A list of trusted paymasters to whitelist in SmartAccounts.
     */
    constructor(IEntryPoint _entryPoint, address[] memory _allowedPaymasters) {
        accountImplementation = new SmartAccount(_entryPoint);
        senderCreator = _entryPoint.senderCreator();
        allowedPaymasters = _allowedPaymasters;
    }

    /**
     * @notice Deploys a SmartAccount using CREATE2 if it doesn’t already exist.
     * @param owner The EOA that will control the deployed SmartAccount.
     * @param salt The deterministic salt used for CREATE2.
     * @return ret The deployed SmartAccount (or existing if already deployed).
     */
    function createAccount(
        address owner,
        uint256 salt
    ) public returns (SmartAccount ret) {
        if (msg.sender != address(senderCreator)) {
            revert OnlySenderCreatorAllowed();
        }

        address addr = getAddress(owner, salt);
        if (addr.code.length > 0) {
            return SmartAccount(payable(addr)); // no event emitted if already exists
        }

        // Deploy a proxy pointing to the base implementation and call initialize()
        ret = SmartAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(
                        SmartAccount.initialize,
                        (owner, allowedPaymasters)
                    )
                )
            )
        );

        emit AccountCreated(address(ret), owner, salt);
    }

    /**
     * @notice Computes the deterministic address of a SmartAccount before deployment.
     * @param owner The EOA that will control the deployed SmartAccount.
     * @param salt The deterministic salt used for CREATE2.
     * @return addr The computed SmartAccount address.
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address addr) {
        bytes memory initCode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                address(accountImplementation),
                abi.encodeCall(
                    SmartAccount.initialize,
                    (owner, allowedPaymasters)
                )
            )
        );
        addr = Create2.computeAddress(bytes32(salt), keccak256(initCode));
        return addr;
    }
}
