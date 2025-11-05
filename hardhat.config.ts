import "dotenv-flow/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY = process.env.PRIVATE_KEY as string;

if (!PRIVATE_KEY?.startsWith("0x"))
  throw new Error("PRIVATE_KEY is missing or not 0x-prefixed");

const config: HardhatUserConfig = {
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
    },

    // Ethereum Sepolia Testnet
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
    },

    // Base Mainnet
    base: {
      url: `https://base-mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 8453,
      accounts: [PRIVATE_KEY],
    },

    // Base Sepolia
    baseSepolia: {
      url: `https://base-sepolia.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 84532,
      accounts: [PRIVATE_KEY],
    },

    // Polygon Mainnet
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 137,
      accounts: [PRIVATE_KEY],
    },

    // Polygon Mainnet
    polygonAmoy: {
      url: `https://polygon-amoy.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 80002,
      accounts: [PRIVATE_KEY],
    },
  },
};

export default config;
