import "dotenv/config";
import { ethers } from "hardhat";

import { logger } from "../utils/logger";

const SPONSOR_ADDRESS = "0xf0BF1971B04787fC0dE4f8Ad40d00EAC2562f9A8";

async function main() {
  // ========================================
  // 1. Get deployer account from the current network
  // ========================================
  const [deployer] = await ethers.getSigners();
  let nonce = await deployer.getNonce("pending");
  logger.info(`Deploying with account: ${deployer.address}`);

  // ========================================
  // 2. Deploy the Delegation contract
  // ========================================
  const Delegation = await ethers.getContractFactory("HinomaruDelegation");
  const delegation = await Delegation.deploy(
    SPONSOR_ADDRESS,
    deployer.address,
    {
      nonce: nonce++,
    },
  );
  await delegation.waitForDeployment();
  await delegation.deploymentTransaction()?.wait();
  logger.info(`✅ Delegation deployed at: ${delegation.target.toString()}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    logger.error(err);
    process.exit(1);
  });
