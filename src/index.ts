import "dotenv/config";
import { ethers } from "hardhat";
import * as v from "valibot";

import { EnvironmentSchema } from "./schemas/EnvironmentSchema";
import { logger } from "./utils/logger";

async function main() {
  // ========================================
  // 1. Load and validate environment variables from .env
  // ========================================
  const rawEnv = {
    JPYC_TOKEN_ADDRESS: process.env.JPYC_TOKEN_ADDRESS,
    USDC_TOKEN_ADDRESS: process.env.USDC_TOKEN_ADDRESS,
    EURC_TOKEN_ADDRESS: process.env.EURC_TOKEN_ADDRESS,
  };
  const environment = v.parse(EnvironmentSchema, rawEnv);

  // ========================================
  // 2. Get deployer account from the current network
  // ========================================
  const [deployer] = await ethers.getSigners();
  logger.info(`Deploying with account: ${deployer.address}`);

  // ========================================
  // 3. Deploy the EntryPoint contract (EIP-4337 core)
  // ========================================
  // Deploy the core EntryPoint contract. This will coordinate UserOperation execution.
  const EntryPoint = await ethers.getContractFactory("EntryPoint");
  const entryPoint = await EntryPoint.deploy();
  await entryPoint.waitForDeployment();
  logger.info(`✅ EntryPoint deployed at: ${entryPoint.target.toString()}`);

  // ========================================
  // 4. Deploy Paymaster contracts for JPYC, USDC, EURC (each with initial fee)
  // ========================================
  // Set the initial fixed fee for each Paymaster (for 1 JPY worth of token, based on August 2025 FX rates).
  const JPYC_FEE = 1000000000; // 1 JPYC (9 decimals)
  const USDC_FEE = 6450; // ~1 JPY (6 decimals, ~0.00645 USDC)
  const EURC_FEE = 5880; // ~1 JPY (6 decimals, ~0.00588 EURC)

  // --- Deploy JPYC Paymaster ---
  const JpycTokenPaymaster =
    await ethers.getContractFactory("JpycTokenPaymaster");
  const jpycPaymaster = await JpycTokenPaymaster.deploy(
    entryPoint,
    environment.JPYC_TOKEN_ADDRESS,
    JPYC_FEE,
  );
  await jpycPaymaster.waitForDeployment();
  logger.info(
    `✅ JpycTokenPaymaster deployed at: ${jpycPaymaster.target.toString()}`,
  );

  // --- Deploy USDC Paymaster ---
  const UsdcTokenPaymaster =
    await ethers.getContractFactory("UsdcTokenPaymaster");
  const usdcPaymaster = await UsdcTokenPaymaster.deploy(
    entryPoint,
    environment.USDC_TOKEN_ADDRESS,
    USDC_FEE,
  );
  await usdcPaymaster.waitForDeployment();
  logger.info(
    `✅ UsdcTokenPaymaster deployed at: ${usdcPaymaster.target.toString()}`,
  );

  // --- Deploy EURC Paymaster ---
  const EurcTokenPaymaster =
    await ethers.getContractFactory("EurcTokenPaymaster");
  const eurcPaymaster = await EurcTokenPaymaster.deploy(
    entryPoint,
    environment.EURC_TOKEN_ADDRESS,
    EURC_FEE,
  );
  await eurcPaymaster.waitForDeployment();
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
    entryPoint,
    allowedPaymasters,
  );
  await accountFactory.waitForDeployment();
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
