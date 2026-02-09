# Shackw Wallet Contracts

Smart contracts powering the core on-chain infrastructure of **Shackw Wallet**.

This repository contains the **EIP-7702–based smart contracts** used by Shackw Wallet.
The contracts are designed around a **delegated account model** and intentionally do **not**
support legacy EOA-based transaction flows.

This document describes the **contract architecture**, supported networks,
and deployment assumptions.

---

# 1. Overview

The **Shackw Wallet Contracts** implement the on-chain primitives required for
Shackw Wallet’s **account abstraction and gas abstraction model**.

Key characteristics:

- Fully based on **EIP-7702 (Delegated Account)** semantics
- No dependency on legacy EOA-based execution
- Designed to work with relay-based execution models
- Explicit separation between **delegation logic** and **registry / nonce management**

These contracts form a core trust boundary between the Shackw Wallet client
and the blockchain.

---

# 2. Core Concepts

## 2.1 Delegated Account Model (EIP-7702)

All contracts assume the **EIP-7702 delegated account model**:

- Users sign **authorization messages**, not transactions
- Execution rights are delegated to a contract for a limited scope
- The delegate contract enforces:
  - signer identity
  - call constraints
  - expiry
  - nonce usage

This repository is designed specifically for EIP-7702-compatible clients.

---

## 2.2 Registry

The **Registry** contract is responsible for:

- tracking per-account nonces
- enforcing global replay protection
- acting as a shared coordination point for delegated execution

The registry is intentionally minimal and does not encode business logic.

---

## 2.3 Delegate

The **Delegate** contract is responsible for:

- validating EIP-7702 authorization payloads
- enforcing execution constraints
- performing delegated calls on behalf of users
- integrating gas / fee abstraction logic where applicable

Concrete fee or token policies (e.g. JPYC-based fees) are treated as **configuration**, not protocol rules.

---

# 3. Supported Networks

The contracts are deployed on multiple EVM-compatible networks.
Exact availability may change over time.

### Ethereum Mainnet

- **Registry**: `0xb631172683DA82B2C87D8f84E2C51698D0719e8C`
- **Delegate**: `0xeD269D025dCed3a7d192923BFaaf605ef830e338`

### Ethereum Sepolia

- **Registry**: `0xeD269D025dCed3a7d192923BFaaf605ef830e338`
- **Delegate**: `0xA9Ea67F7A3990d40745Dfb46D61e3A416a8018a2`

### Base Mainnet

- **Registry**: `0xaf264eaB8D01A54F064Ee17951aA6b6f3836DC26`
- **Delegate**: `0xb820D66Ba5501232a3CF4a00FdF9e3f0e5eCE85C`

### Base Sepolia

- **Registry**: `0x2493548c692c3Ff919000A6e788Cc0E2047d11E0`
- **Delegate**: `0xe6D0F40a9933C176b3BE5D9830D8E564400c8231`

### Polygon Mainnet

- **Registry**: `0xb631172683DA82B2C87D8f84E2C51698D0719e8C`
- **Delegate**: `0xeD269D025dCed3a7d192923BFaaf605ef830e338`

### Polygon Amoy

- **Registry**: `0x773c5cA412751a5a2cD24e4d706bb417AFF2F531`
- **Delegate**: `0x3f80037AeC2DFfd88a193c58161bB1CDcA1ecF6a`

> ⚠️ Contract addresses are provided for reference.
> Clients should treat them as environment-specific configuration.

---

# 4. Development Notes

## 4.1 Tooling

- Solidity
- Hardhat
- TypeScript
- OpenZeppelin Contracts
- Solhint / Prettier (Solidity)

## 4.2 Commands

```bash
# clean build artifacts
yarn clean

# lint Solidity and TypeScript
yarn lint

# format source files
yarn format

# deploy EIP-7702 contracts
yarn deploy-eip7702:<network>

```

---

# 5. Security Notes

- All contracts assume **off-chain authorization signing (EIP-7702)**.
  Users sign authorization messages locally; raw transactions are never signed by end users.

- No private keys, secrets, or credentials are stored or managed on-chain.

- Replay protection and nonce consumption are **centralized in the Registry contract**
  to ensure consistent and auditable execution control.

- Execution constraints and business rules are enforced at the
  **Delegate contract layer**, not embedded in client logic.

- Deployment keys, environment variables, and operational secrets are
  intentionally excluded from this repository.

This repository contains **only deterministic smart contract logic** and is designed
to be verifiable, reproducible, and environment-agnostic.

---

# 6. Protocol Scope & Compatibility

- These contracts **exclusively support EIP-7702 (Delegated Account)**–based execution.
  No other account abstraction models are supported.

- Legacy **EOA-based transactions** are intentionally out of scope.

- Any tooling, wallet, or bundler interacting with these contracts must be
  **EIP-7702–aware by design**.

---

# 7. Design Intent

- The contracts are designed to be **minimal, explicit, and opinionated**.
  They intentionally avoid generalized abstraction layers.

- EIP-7702 is treated as a **protocol-level assumption**, not a pluggable feature.

- Gas abstraction, fee policies, and execution constraints are enforced
  **on-chain**, not delegated to off-chain heuristics.

- The contract architecture favors:
  - clear trust boundaries
  - deterministic execution paths
  - auditable authorization logic

This repository prioritizes **correctness and clarity over extensibility**.

---

# 8. License

Internal use only unless otherwise specified.  
License terms may be clarified in the future.

---

## Author

**Shackw**
