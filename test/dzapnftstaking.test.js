const { expect } = require("chai");
const { Console } = require("console");
const { ethers, network, upgrades } = require("hardhat");

describe("DzapNFTStaking", function () {
  let dzapNFTStaking;
  let mockNFT;
  let mockRewardToken;
  let owner;
  let user1;
  let user2;

  const REWARD_PER_BLOCK = "100000000000000000";
  const DELAY_PERIOD = 120; // 2 Mins
  const UNBONDING_PERIOD = 120; // 2 Mins

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    // console.log(await user1.getAddress());

    // Deploy mock NFT contract
    const MockNFT = await ethers.getContractFactory("MockERC721");
    mockNFT = await MockNFT.deploy();
    // await mockNFT.deployed();

    // Deploy mock reward token contract
    const MockRewardToken = await ethers.getContractFactory("MockERC20");
    mockRewardToken = await MockRewardToken.deploy();
    // await mockRewardToken.deployed();

    // Deploy DzapNFTStaking contract (upgradeable)
    const DzapNFTStaking = await ethers.getContractFactory("DzapNFTStaking");
    dzapNFTStaking = await upgrades.deployProxy(DzapNFTStaking, [], {
      initializer: "initialize",
    });

    await dzapNFTStaking.setContractData(
      await mockNFT.getAddress(),
      await mockRewardToken.getAddress(),
      REWARD_PER_BLOCK,
      DELAY_PERIOD,
      UNBONDING_PERIOD
    );

    // Unpause the contract
    await dzapNFTStaking.unpause();

    // Mint NFTs to users
    await mockNFT.mint(await user1.getAddress());
    await mockNFT.mint(await user2.getAddress());

    const stakeAddr = await dzapNFTStaking.getAddress();
    // Mint reward tokens to the staking contract
    await mockRewardToken.mint(stakeAddr, "1000000000000000000000000");

    // Approve NFTs for staking
    await mockNFT.connect(user1).approve(stakeAddr, 1);
    await mockNFT.connect(user2).approve(stakeAddr, 2);
  });

  it("Should set the correct reward token address", async function () {
    expect(await dzapNFTStaking.rewardToken()).to.equal(
      await mockRewardToken.getAddress()
    );
  });

  it("Should set the correct reward per block", async function () {
    expect(await dzapNFTStaking.rewardPerBlock()).to.be.equal(REWARD_PER_BLOCK);
  });

  it("Should set the correct delay period", async function () {
    expect(await dzapNFTStaking.delayPeriod()).to.equal(DELAY_PERIOD);
  });

  it("Should set the correct unbonding period", async function () {
    expect(await dzapNFTStaking.unbondingPeriod()).to.equal(UNBONDING_PERIOD);
  });
  it("Should return the correct version", async function () {
    expect(await dzapNFTStaking.version()).to.equal("1.0.0");
  });
  it("Should not allow non-owner to update reward per block", async function () {
    expect(dzapNFTStaking.connect(user1).updateRewardPerBlock(200)).to.be
      .reverted;
  });

  it("Should not allow non-owner to pause", async function () {
    expect(dzapNFTStaking.connect(user1).pause()).to.be.reverted;
  });

  it("Should not allow non-owner to unpause", async function () {
    expect(dzapNFTStaking.connect(user1).unpause()).to.be.reverted;
  });

  it("Should not allow non-owner to update delay period", async function () {
    expect(dzapNFTStaking.connect(user1).updateDelayPeriod(300)).to.be.reverted;
  });

  it("Should not allow non-owner to update unbonding period", async function () {
    expect(dzapNFTStaking.connect(user1).updateUnbondingPeriod(300)).to.be
      .reverted;
  });
  it("Should not allow non-owner to set contract data", async function () {
    expect(
      dzapNFTStaking
        .connect(user1)
        .setContractData(
          mockNFT.address,
          mockRewardToken.address,
          REWARD_PER_BLOCK,
          DELAY_PERIOD,
          UNBONDING_PERIOD
        )
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  describe("Staking", function () {
    it("Should allow a user to stake their NFT", async function () {
      expect(await dzapNFTStaking.connect(user1).stakeNFT(1))
        .to.emit(dzapNFTStaking, "NFTStaked")
        .withArgs(user1.address, 1);

      const stakedNFT = await dzapNFTStaking.stakedNFTs(1);
      expect(stakedNFT.owner).to.equal(await user1.getAddress());
      expect(stakedNFT.status).to.equal(1); // STAKED
    });

    it("Should not allow staking of an already staked NFT", async function () {
      await dzapNFTStaking.connect(user1).stakeNFT(1);
      expect(dzapNFTStaking.connect(user1).stakeNFT(1)).to.be.reverted;
    });

    it("Should not allow staking when paused", async function () {
      await dzapNFTStaking.pause();
      expect(dzapNFTStaking.connect(user1).stakeNFT(1)).to.be.reverted;
    });
    it("Should not allow staking of an NFT the user doesn't own", async function () {
      expect(dzapNFTStaking.connect(user2).stakeNFT(1)).to.be.reverted;
    });
  });

  describe("Unstaking", function () {
    beforeEach(async function () {
      await dzapNFTStaking.connect(user1).stakeNFT(1);
    });

    it("Should allow a user to unstake their NFT", async function () {
      expect(await dzapNFTStaking.connect(user1).unstakeNFT(1))
        .to.emit(dzapNFTStaking, "NFTUnstaked")
        .withArgs(user1.address, 1);

      const stakedNFT = await dzapNFTStaking.stakedNFTs(1);
      expect(stakedNFT.status).to.equal(2); // UNSTAKED
    });

    it("Should not allow unstaking of an unstaked NFT", async function () {
      await dzapNFTStaking.connect(user1).unstakeNFT(1);
      await expect(
        dzapNFTStaking.connect(user1).unstakeNFT(1)
      ).to.be.revertedWith("DzapNFTStaking: Nft is not staked!");
    });

    it("Should not allow unstaking by non-owner", async function () {
      await expect(
        dzapNFTStaking.connect(user2).unstakeNFT(1)
      ).to.be.revertedWith("DzapNFTStaking: User is not authorized!");
    });
  });

  describe("Withdrawing", function () {
    beforeEach(async function () {
      await dzapNFTStaking.connect(user1).stakeNFT(1);
      await dzapNFTStaking.connect(user1).unstakeNFT(1);
    });

    it("Should not allow withdrawal before unbonding period", async function () {
      expect(dzapNFTStaking.connect(user1).withdrawNFT(1)).to.be.revertedWith(
        "Invalid asset state"
      );
    });

    it("Should allow withdrawal after unbonding period", async function () {
      // await network.provider.send("evm_increaseTime", [180]);
      await network.provider.send("hardhat_mine", [0x100]);
      expect(await dzapNFTStaking.connect(user1).withdrawNFT(1))
        .to.emit(dzapNFTStaking, "NFTWithdrawn")
        .withArgs(user1.address, 1);

      expect(await mockNFT.ownerOf(1)).to.equal(user1.address);
    });
  });

  describe("Claiming Rewards", function () {
    beforeEach(async function () {
      await dzapNFTStaking.connect(user1).stakeNFT(1);
    });

    it("Should allow claiming rewards after delay period", async function () {
      await network.provider.send("hardhat_mine", [0x100]);

      const initialBalance = await mockRewardToken.balanceOf(user1.address);
      await dzapNFTStaking.connect(user1).claimRewards(1);
      const finalBalance = await mockRewardToken.balanceOf(user1.address);

      expect(finalBalance > initialBalance).to.be.true;
    });

    it("Should not allow claiming rewards before delay period", async function () {
      expect(dzapNFTStaking.connect(user1).claimRewards(1)).to.be.revertedWith(
        "Claim delay period not met"
      );
    });

    it("Should calculate rewards correctly for unstaking NFT", async function () {
      // Unstake the NFT
      await dzapNFTStaking.connect(user1).unstakeNFT(1);

      await network.provider.send("hardhat_mine", [0x10]);

      const initialBalance = await mockRewardToken.balanceOf(user1.address);

      // Claim rewards
      await dzapNFTStaking.connect(user1).claimRewards(1);

      const finalBalance = await mockRewardToken.balanceOf(user1.address);

      const expectedRewards = REWARD_PER_BLOCK; // 80 blocks of staking

      expect(finalBalance - initialBalance).to.be.equal(expectedRewards);

      // Check that lastblock is set to 0 after claiming
      const updatedStakedNFT = await dzapNFTStaking.stakedNFTs(1);
      expect(updatedStakedNFT.lastblock).to.be.equal(0);
    });
    it("Should not allow claiming rewards for a non-staked NFT", async function () {
      expect(dzapNFTStaking.connect(user1).claimRewards(1)).to.be.reverted;
    });

    it("Should not allow claiming rewards before the delay period", async function () {
      expect(dzapNFTStaking.connect(user1).claimRewards(1)).to.be.reverted;
    });

    it("Should not allow claiming zero rewards", async function () {
      await network.provider.send("hardhat_mine", ["0x1"]); // Mine 1 block
      expect(dzapNFTStaking.connect(user1).claimRewards(1)).to.be.reverted;
    });
  });

  describe("Owner Functions", function () {
    it("Should allow owner to update reward per block", async function () {
      const newRewardPerBlock = "200000000000000000";
      await dzapNFTStaking.updateRewardPerBlock(newRewardPerBlock);
      expect(await dzapNFTStaking.rewardPerBlock()).to.equal(newRewardPerBlock);
    });

    it("Should allow owner to pause and unpause the contract", async function () {
      await dzapNFTStaking.pause();
      expect(dzapNFTStaking.connect(user1).stakeNFT(1)).to.be.reverted;

      await dzapNFTStaking.unpause();
    });

    it("Should allow owner to update delay period", async function () {
      const newDelayPeriod = 7200;
      await dzapNFTStaking.updateDelayPeriod(newDelayPeriod);
      expect(await dzapNFTStaking.delayPeriod()).to.equal(newDelayPeriod);
    });

    it("Should allow owner to update unbonding period", async function () {
      const newUnbondingPeriod = 172800;
      await dzapNFTStaking.updateUnbondingPeriod(newUnbondingPeriod);
      expect(await dzapNFTStaking.unbondingPeriod()).to.equal(
        newUnbondingPeriod
      );
    });
  });
});
