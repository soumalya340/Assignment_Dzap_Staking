// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const DzapNFTStakingFactory = await ethers.getContractFactory(
    "DzapNFTStaking"
  );
  const stake = await upgrades.deployProxy(DzapNFTStakingFactory, [42]);
  await stake.waitForDeployment();
  console.log("DzapNFTStaking deployed to:", await box.getAddress());
}

main();
