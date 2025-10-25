# hinomaru-wallet-contracts

Smart contracts powering the core infrastructure of **HinomaruWallet**.

## Overview

This repository contains smart contracts that **fully adopt the EIP-7702 “Delegated Account” model**.
They are **not compatible with legacy EOA-based (EIP-4337) flows** and are designed to work exclusively with
EIP-7702-compatible wallets and bundlers.

## Features

- Implements **Paymaster contracts** for gas abstraction using **JPYC**
- Fully **EIP-7702-compliant** (delegated smart account architecture)
- Supports **Base**, **Ethereum**, and their **Sepolia** test networks
- Built with **Solidity**, **Hardhat**, and **TypeScript**

## Contract Addresses

### Ethereum Mainnet
- **Delegation**: `0xb820D66Ba5501232a3CF4a00FdF9e3f0e5eCE85C`
- **Registry**: `0xaf264eaB8D01A54F064Ee17951aA6b6f3836DC26`

### Ethereum Sepolia
- **Delegation**: `0x160ce681bfe7AFfC6aB5A4034b68d526CD178C00`
- **Registry**: `0xA30E5b7a152DD4B7b31838B3e81665D0D99dBe69`

### Base Mainnet
- **Delegation**: `0x9C928a2CD9FD82e84dB006db7c917012ffB56C33`
- **Registry**: `0x30F8bf6e250DA7D2D7FCC50e0AA57d8f29b500Cd`

### Base Sepolia
- **Delegation**: `0x1997f7094560eF4B0D8a466CA06619B41C68B14B`
- **Registry**: `0x0e8B61d5abB89197fC098E3133fbC351d09A105c`

## Author

**FickleWolf**