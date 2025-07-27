import "dotenv-flow/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

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
    baseSepolia: {
      url: "https://sepolia.base.org/rpc",
      accounts: [process.env.PRIVATE_KEY as string],
    },
    base: {
      url: "https://base.mainnet.rpc.url",
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
};

export default config;
