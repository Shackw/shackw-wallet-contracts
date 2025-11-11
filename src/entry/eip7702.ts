import "dotenv/config";
import hre from "hardhat";

import { logger } from "../utils/logger.js";

const SPONSOR_ADDRESS = "0xf0BF1971B04787fC0dE4f8Ad40d00EAC2562f9A8";

async function main() {
  const { ethers } = await hre.network.connect();

  // ========================================
  // 1. Get deployer account from the current network
  // ========================================
  const [deployer] = await ethers.getSigners();
  let nonce = await deployer.getNonce("pending");
  logger.info(`Deploying with account: ${deployer.address}`);

  // ========================================
  // 2. Deploy the Registry contract
  // ========================================
  const Registry = await ethers.getContractFactory("ShackwRegistry");
  const registry = await Registry.deploy(deployer.address, SPONSOR_ADDRESS, {
    nonce: nonce++,
  });
  await registry.waitForDeployment();
  await registry.deploymentTransaction()?.wait();
  logger.info(`✅ Registry deployed at: ${registry.target.toString()}`);

  // ========================================
  // 3. Deploy the Delegation contract
  // ========================================
  const Delegation = await ethers.getContractFactory("ShackwDelegate");
  const delegation = await Delegation.deploy(registry.target, {
    nonce: nonce++,
  });
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
