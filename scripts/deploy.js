const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const PredictionMarket = await ethers.getContractFactory("PredictionMarket");
  const contract = await PredictionMarket.deploy(deployer.address);

  await contract.deployed();
  console.log("PredictionMarket deployed at:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
