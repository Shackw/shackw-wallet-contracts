import "dotenv-flow/config";

import toolbox from "@nomicfoundation/hardhat-ignition-ethers";
import { defineConfig } from "hardhat/config";

const PRIVATE_KEY = process.env.PRIVATE_KEY as string;

if (!PRIVATE_KEY?.startsWith("0x"))
  throw new Error("PRIVATE_KEY is missing or not 0x-prefixed");

export default defineConfig({
  plugins: [toolbox],
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          evmVersion: "cancun",
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    ],
  },
  networks: {
    // Ethereum Mainnet
    main: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 1,
      accounts: [PRIVATE_KEY],
      type: "http",
    },

    // Ethereum Sepolia Testnet
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
      type: "http",
    },

    // Base Mainnet
    base: {
      url: `https://base-mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 8453,
      accounts: [PRIVATE_KEY],
      type: "http",
    },

    // Base Sepolia
    baseSepolia: {
      url: `https://base-sepolia.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 84532,
      accounts: [PRIVATE_KEY],
      type: "http",
    },

    // Polygon Mainnet
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 137,
      accounts: [PRIVATE_KEY],
      type: "http",
    },

    // Polygon Amoy
    polygonAmoy: {
      url: `https://polygon-amoy.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 80002,
      accounts: [PRIVATE_KEY],
      type: "http",
    },
  },
});
