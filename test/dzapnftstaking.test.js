const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("Nft Contract", () => {
  before(async () => {
    [owner, operator, creator, creator2, buyer] = await ethers.getSigners();
  });

  let nft;

  before(async () => {
    const nftFactory = await ethers.getContractFactory("SPNFT");
    nft = await nftFactory.deploy(owner.address);
    nft.deployed();
  });

  it("Should return the right name and symbol of the token once nft is deployed", async () => {
    const name = "SPNFT";
    const symbol = "SNFT";
    expect(await nft.name()).to.equal(name);
    expect(await nft.symbol()).to.equal(symbol);
  });

  it("Should get the right owner", async () => {
    const ADMIN_ROLE = await nft.DEFAULT_ADMIN_ROLE();
    expect(await nft.hasRole(ADMIN_ROLE, owner.address)).to.be.true;
  });

  it("Should able to  create a NFT by everyone", async () => {
    await nft.createAsset("www.xyz.com");
    expect(await nft.balanceOf(owner.address)).to.be.equal(1);
  });

  it("Should able to  destroyed a NFT only by owner", async () => {
    ///Test Case 01: No one other than owner can burn a nft
    await expect(nft.connect(creator).destroyAsset(1)).to.be.reverted;

    await nft.destroyAsset(1);

    expect(await nft.balanceOf(owner.address)).to.be.equal(0);
  });
});
