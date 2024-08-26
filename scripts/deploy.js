// imports
const { ethers, run, network } = require("hardhat");
// async main
async function main() {
  const accounts = await ethers.getSigners();
  const NftFactory = await ethers.getContractFactory("Dzap");
  console.log("Deploying contract...");

  const Nft = await NftFactory.deploy(accounts[0].address);
  await Nft.deployed();
  console.log(`Deployed Nft contract to: ${Nft.address}`);
  if (network.name != "hardhat") {
    console.log("Waiting for block confirmations...");
    await Nft.deployTransaction.wait(6);
    await verify(Nft.address, [accounts[0].address]);
  }
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!");
    } else {
      console.log(e);
    }
  }
};

// main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
