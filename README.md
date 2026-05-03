# Shackw Wallet Contracts

EIP-7702 smart contracts for Shackw Wallet.

Built with Hardhat + Solidity.

---

## Overview

- EIP-7702 delegated account model
- **Delegate** — validates authorization, enforces execution constraints, performs delegated calls
- **Registry** — per-account nonce management and replay protection

---

## Deployed Addresses

| Network | Registry | Delegate |
|---|---|---|
| Polygon Mainnet | `0xb631172683DA82B2C87D8f84E2C51698D0719e8C` | `0xeD269D025dCed3a7d192923BFaaf605ef830e338` |
| Polygon Amoy | `0x773c5cA412751a5a2cD24e4d706bb417AFF2F531` | `0x3f80037AeC2DFfd88a193c58161bB1CDcA1ecF6a` |

---

## Development

```bash
yarn clean
yarn lint
yarn format
yarn deploy-eip7702:<network>
```

---

## Security

- Authorization signing is performed off-chain (EIP-7702)
- Replay protection is centralized in the Registry
- Execution constraints are enforced at the Delegate layer
- No private keys or secrets are stored on-chain

---

## License

MIT

## Author

**Shackw**