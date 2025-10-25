import { Wallet } from "ethers";

const main = () => {
  const wallet = Wallet.createRandom();

  console.log("Public address:", wallet.address);
  console.log("Private key:", wallet.privateKey);
};

main();
