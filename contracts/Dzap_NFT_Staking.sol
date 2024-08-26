// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DzapNFTStaking is Ownable, ReentrancyGuard {
    IERC721 public nftContract;
    IERC20 public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public delayPeriod;
    uint256 public unbondingPeriod;
    bool private _pause;

    struct AssetInfo {
        address owner;
        uint256 lastblock;
        uint256 unbondingEndTime;
        uint256 untstakingEndBlock;
        AssetStatus status;
    }
    enum AssetStatus {
        NOTSTAKED,
        STAKED,
        UNSTAKING_IN_PROGRESS,
        UNSTAKED
    }
    // Mapping from staker to their staked NFTs
    mapping(uint256 => AssetInfo) public stakedNFTs;
    // Mapping from staker to their last reward claim timestamp
    mapping(address => uint256) public lastClaimTimestamp;

    modifier whenNotpaused() {
        require(
            _pause == false,
            "DzapNFTStaking: The user cannot proceed ,contract is _paused"
        );
        _;
    }
    modifier onlywhenTokenOwner(uint256 tokenId) {
        require(
            stakedNFTs[tokenId].owner == _msgSender(),
            "DzapNFTStaking: User is not authorized!"
        );
        _;
    }
    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event NFTWithdrawn(address indexed user, uint256 tokenId);

    constructor(
        address _nftContract,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _delayPeriod,
        uint256 _unbondingPeriod
    ) Ownable(_msgSender()) {
        nftContract = IERC721(_nftContract);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        delayPeriod = _delayPeriod;
        unbondingPeriod = _unbondingPeriod;
        _pause = true; // Start the contract in _paused state to prevent actions until it's ready
    }

    function stakeNFT(
        uint256 tokenId
    ) external whenNotpaused onlywhenTokenOwner(tokenId) {
        require(
            stakedNFTs[tokenId].status == AssetStatus.NOTSTAKED ||
                stakedNFTs[tokenId].status == AssetStatus.UNSTAKED,
            "DzapNFTStaking: Asset is already staked"
        );
        nftContract.transferFrom(_msgSender(), address(this), tokenId);
        stakedNFTs[tokenId] = AssetInfo(
            _msgSender(),
            block.number,
            0,
            0,
            AssetStatus.STAKED
        );
        emit NFTStaked(_msgSender(), tokenId);
    }

    function unstakeNFT(
        uint256 tokenId
    ) external nonReentrant onlywhenTokenOwner(tokenId) {
        require(
            stakedNFTs[tokenId].status == AssetStatus.STAKED,
            "DzapNFTStaking: Nft is not staked!"
        );

        stakedNFTs[tokenId].unbondingEndTime =
            block.timestamp +
            unbondingPeriod;

        stakedNFTs[tokenId].untstakingEndBlock = block.number;
        stakedNFTs[tokenId].status = AssetStatus.UNSTAKED;

        emit NFTUnstaked(_msgSender(), tokenId);
    }

    function withdrawNFT(uint256 tokenId) external {
        require(
            stakedNFTs[tokenId].status == AssetStatus.UNSTAKING_IN_PROGRESS,
            "Invalid asset state"
        );
        require(
            block.timestamp >= stakedNFTs[tokenId].unbondingEndTime,
            "Unbonding period not over"
        );

        stakedNFTs[tokenId].status == AssetStatus.UNSTAKED;

        nftContract.transferFrom(
            address(this),
            stakedNFTs[tokenId].owner,
            tokenId
        );

        emit NFTWithdrawn(_msgSender(), tokenId);
    }

    function claimRewards(
        uint256 tokenId
    ) external nonReentrant onlywhenTokenOwner(tokenId) {
        require(
            stakedNFTs[tokenId].status != AssetStatus.NOTSTAKED,
            "Asset is not staked"
        );

        require(
            block.timestamp >= lastClaimTimestamp[_msgSender()] + delayPeriod,
            "Claim delay period not met"
        );

        uint256 rewards;

        if (
            stakedNFTs[tokenId].status != AssetStatus.STAKED &&
            stakedNFTs[tokenId].lastblock != 0
        ) {
            uint256 numBlocks = stakedNFTs[tokenId].untstakingEndBlock -
                stakedNFTs[tokenId].lastblock;

            rewards = numBlocks * rewardPerBlock;

            stakedNFTs[tokenId].lastblock = 0;
        } else {
            uint256 numBlocks = block.number - stakedNFTs[tokenId].lastblock;

            rewards = numBlocks * rewardPerBlock;

            stakedNFTs[tokenId].lastblock = block.number;
        }

        require(rewards > 0, "No rewards to claim");

        lastClaimTimestamp[_msgSender()] = block.timestamp + delayPeriod;

        require(
            rewardToken.transfer(_msgSender(), rewards),
            "Reward transfer failed"
        );

        emit RewardsClaimed(_msgSender(), rewards);
    }

    function updateRewardPerBlock(
        uint256 _newRewardPerBlock
    ) external onlyOwner {
        rewardPerBlock = _newRewardPerBlock;
    }

    function pause() external onlyOwner {
        _pause = true;
    }

    function unpause() external onlyOwner {
        _pause = false;
    }

    function updateDelayPeriod(uint256 _newDelayPeriod) external onlyOwner {
        delayPeriod = _newDelayPeriod;
    }

    function updateUnbondingPeriod(
        uint256 _newUnbondingPeriod
    ) external onlyOwner {
        unbondingPeriod = _newUnbondingPeriod;
    }
}
