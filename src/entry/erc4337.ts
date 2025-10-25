import "dotenv/config";
import { ethers } from "hardhat";
import * as v from "valibot";

import { EnvSchema } from "../schemas/erc4337.schema";
import { logger } from "../utils/logger";

async function main() {
  // ========================================
  // 1. Load and validate environment variables from .env
  // ========================================
  const rawEnv = {
    JPYC_TOKEN_ADDRESS: process.env.JPYC_TOKEN_ADDRESS,
    USDC_TOKEN_ADDRESS: process.env.USDC_TOKEN_ADDRESS,
    EURC_TOKEN_ADDRESS: process.env.EURC_TOKEN_ADDRESS,
    JPYC_TRUSTED_SIGNER: process.env.JPYC_TRUSTED_SIGNER_ADDRESS,
    USDC_TRUSTED_SIGNER: process.env.USDC_TRUSTED_SIGNER_ADDRESS,
    EURC_TRUSTED_SIGNER: process.env.EURC_TRUSTED_SIGNER_ADDRESS,
  };
  const environment = v.parse(EnvSchema, rawEnv);

  // ========================================
  // 2. Get deployer account from the current network
  // ========================================
  const [deployer] = await ethers.getSigners();
  let nonce = await deployer.getNonce("pending");
  logger.info(`Deploying with account: ${deployer.address}`);

  // ========================================
  // 3. Deploy the EntryPoint contract (EIP-4337 core)
  // ========================================
  // Deploy the core EntryPoint contract. This will coordinate UserOperation execution.
  const EntryPoint = await ethers.getContractFactory("EntryPoint");
  const entryPoint = await EntryPoint.deploy({ nonce: nonce++ });
  await entryPoint.waitForDeployment();
  await entryPoint.deploymentTransaction()?.wait();
  logger.info(`✅ EntryPoint deployed at: ${entryPoint.target.toString()}`);

  // ========================================
  // 4. Deploy Paymaster contracts for JPYC, USDC, EURC (each with initial fee)
  // ========================================

  // --- Deploy JPYC Paymaster ---
  const JpycTokenPaymaster =
    await ethers.getContractFactory("JpycTokenPaymaster");
  const jpycPaymaster = await JpycTokenPaymaster.deploy(
    entryPoint.target,
    environment.JPYC_TOKEN_ADDRESS,
    environment.JPYC_TRUSTED_SIGNER,
    { nonce: nonce++ },
  );
  await jpycPaymaster.waitForDeployment();
  await jpycPaymaster.deploymentTransaction()?.wait();
  logger.info(
    `✅ JpycTokenPaymaster deployed at: ${jpycPaymaster.target.toString()}`,
  );

  // --- Deploy USDC Paymaster ---
  const UsdcTokenPaymaster =
    await ethers.getContractFactory("UsdcTokenPaymaster");
  const usdcPaymaster = await UsdcTokenPaymaster.deploy(
    entryPoint.target,
    environment.USDC_TOKEN_ADDRESS,
    environment.USDC_TRUSTED_SIGNER,
    { nonce: nonce++ },
  );
  await usdcPaymaster.waitForDeployment();
  await usdcPaymaster.deploymentTransaction()?.wait();
  logger.info(
    `✅ UsdcTokenPaymaster deployed at: ${usdcPaymaster.target.toString()}`,
  );

  // --- Deploy EURC Paymaster ---
  const EurcTokenPaymaster =
    await ethers.getContractFactory("EurcTokenPaymaster");
  const eurcPaymaster = await EurcTokenPaymaster.deploy(
    entryPoint.target,
    environment.EURC_TOKEN_ADDRESS,
    environment.EURC_TRUSTED_SIGNER,
    { nonce: nonce++ },
  );
  await eurcPaymaster.waitForDeployment();
  await eurcPaymaster.deploymentTransaction()?.wait();
  logger.info(
    `✅ EurcTokenPaymaster deployed at: ${eurcPaymaster.target.toString()}`,
  );

  // Collect all Paymaster contract addresses into an array for AccountFactory constructor
  const allowedPaymasters: string[] = [
    jpycPaymaster.target.toString(),
    usdcPaymaster.target.toString(),
    eurcPaymaster.target.toString(),
  ];

  // ========================================
  // 5. Deploy AccountFactory with Paymaster addresses (whitelist)
  // ========================================
  // Deploy AccountFactory with the EntryPoint address and the array of allowed Paymaster addresses.
  const AccountFactory = await ethers.getContractFactory("AccountFactory");
  const accountFactory = await AccountFactory.deploy(
    entryPoint.target,
    allowedPaymasters,
    { nonce: nonce++ },
  );
  await accountFactory.waitForDeployment();
  await accountFactory.deploymentTransaction()?.wait();
  logger.info(
    `✅ AccountFactory deployed at: ${accountFactory.target.toString()}`,
  );
}

// Entry point for script execution with error handling
main()
  .then(() => process.exit(0))
  .catch((err) => {
    logger.error(err);
    process.exit(1);
  });
