import "dotenv/config";
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const EntryPoint = await ethers.getContractFactory("EntryPoint");
  const entryPoint = await EntryPoint.deploy();
  await entryPoint.waitForDeployment();
  console.log("✅ EntryPoint deployed at:", entryPoint.target);

  const jpycToken = process.env.JPYC_TOKEN_ADDRESS;
  if (!entryPoint || !jpycToken) {
    throw new Error(
      "Please set ENTRY_POINT_ADDRESS and JPYC_TOKEN_ADDRESS in .env"
    );
  }

  const Paymaster = await ethers.getContractFactory("JpycTokenPaymaster");
  const paymaster = await Paymaster.deploy(entryPoint, jpycToken);
  await paymaster.waitForDeployment();

  console.log("✅ JpycTokenPaymaster deployed at:", paymaster.target);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
