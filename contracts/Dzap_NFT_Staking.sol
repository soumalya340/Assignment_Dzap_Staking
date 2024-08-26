// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title DzapNFTStaking
/// @notice This contract allows users to stake NFTs and earn ERC20 token rewards
/// @dev This contract is upgradeable and uses OpenZeppelin's upgradeable contracts
contract DzapNFTStaking is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    IERC721 public nftContract;
    IERC20 public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public delayPeriod;
    uint256 public unbondingPeriod;
    bool private _pause;

    /// @notice Struct to store information about staked assets
    struct AssetInfo {
        address owner;
        uint256 lastblock;
        uint256 unbondingEndTime;
        uint256 untstakingEndBlock;
        AssetStatus status;
    }

    /// @notice Enum to represent the status of an asset
    enum AssetStatus {
        NOTSTAKED,
        STAKED,
        UNSTAKING_IN_PROGRESS,
        UNSTAKED
    }

    /// @notice Mapping of token IDs to their staking information
    mapping(uint256 => AssetInfo) public stakedNFTs;

    /// @notice Mapping of staker addresses to their last reward claim timestamp
    mapping(address => uint256) public lastClaimTimestamp;

    /// @notice Modifier to check if the contract is not paused
    modifier whenNotpaused() {
        require(
            _pause == false,
            "DzapNFTStaking: The user cannot proceed, contract is paused"
        );
        _;
    }

    /// @notice Modifier to check if the caller is the owner of the token
    /// @param tokenId The ID of the token
    modifier onlywhenTokenOwner(uint256 tokenId) {
        require(
            stakedNFTs[tokenId].owner == _msgSender(),
            "DzapNFTStaking: User is not authorized!"
        );
        _;
    }

    /// @notice Emitted when an NFT is staked
    /// @param user The address of the user who staked the NFT
    /// @param tokenId The ID of the staked NFT
    event NFTStaked(address indexed user, uint256 tokenId);

    /// @notice Emitted when an NFT is unstaked
    /// @param user The address of the user who unstaked the NFT
    /// @param tokenId The ID of the unstaked NFT
    event NFTUnstaked(address indexed user, uint256 tokenId);

    /// @notice Emitted when rewards are claimed
    /// @param user The address of the user who claimed rewards
    /// @param amount The amount of rewards claimed
    event RewardsClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when an NFT is withdrawn
    /// @param user The address of the user who withdrew the NFT
    /// @param tokenId The ID of the withdrawn NFT
    event NFTWithdrawn(address indexed user, uint256 tokenId);

    /// @notice Initializes the contract
    /// @dev This function is called once when the contract is deployed
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _pause = true; // Start the contract in paused state to prevent actions until it's ready
    }

    /// @notice Sets the main contract data
    /// @param _nftContract Address of the NFT contract
    /// @param _rewardToken Address of the reward token contract
    /// @param _rewardPerBlock Amount of reward tokens given per block
    /// @param _delayPeriod Delay period for claiming rewards
    /// @param _unbondingPeriod Period for unbonding staked NFTs
    function setContractData(
        address _nftContract,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _delayPeriod,
        uint256 _unbondingPeriod
    ) external onlyOwner {
        nftContract = IERC721(_nftContract);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        delayPeriod = _delayPeriod;
        unbondingPeriod = _unbondingPeriod;
    }

    /// @notice Allows a user to stake an NFT
    /// @param tokenId The ID of the NFT to stake
    function stakeNFT(uint256 tokenId) external whenNotpaused {
        require(
            stakedNFTs[tokenId].status == AssetStatus.NOTSTAKED ||
                stakedNFTs[tokenId].status == AssetStatus.UNSTAKED,
            "DzapNFTStaking: Asset is already staked"
        );
        require(
            nftContract.ownerOf(tokenId) == _msgSender(),
            "User is not authorized"
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

    /// @notice Allows a user to initiate the unstaking process for an NFT
    /// @param tokenId The ID of the NFT to unstake
    function unstakeNFT(uint256 tokenId) external onlywhenTokenOwner(tokenId) {
        require(
            stakedNFTs[tokenId].status == AssetStatus.STAKED,
            "DzapNFTStaking: Nft is not staked!"
        );

        stakedNFTs[tokenId].unbondingEndTime =
            block.timestamp +
            unbondingPeriod;

        stakedNFTs[tokenId].untstakingEndBlock = block.number;
        stakedNFTs[tokenId].status = AssetStatus.UNSTAKING_IN_PROGRESS;

        emit NFTUnstaked(_msgSender(), tokenId);
    }

    /// @notice Allows a user to withdraw their unstaked NFT after the unbonding period
    /// @param tokenId The ID of the NFT to withdraw
    function withdrawNFT(uint256 tokenId) external {
        require(
            stakedNFTs[tokenId].status == AssetStatus.UNSTAKING_IN_PROGRESS,
            "Invalid asset state"
        );
        require(
            block.timestamp >= stakedNFTs[tokenId].unbondingEndTime,
            "Unbonding period not over"
        );

        stakedNFTs[tokenId].status = AssetStatus.UNSTAKED;

        nftContract.transferFrom(
            address(this),
            stakedNFTs[tokenId].owner,
            tokenId
        );

        emit NFTWithdrawn(_msgSender(), tokenId);
    }

    /// @notice Allows a user to claim rewards for a staked NFT
    /// @param tokenId The ID of the NFT for which to claim rewards
    function claimRewards(
        uint256 tokenId
    ) external onlywhenTokenOwner(tokenId) {
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

        lastClaimTimestamp[_msgSender()] = block.timestamp;

        require(
            rewardToken.transfer(_msgSender(), rewards),
            "Reward transfer failed"
        );

        emit RewardsClaimed(_msgSender(), rewards);
    }

    /// @notice Allows the owner to update the reward per block
    /// @param _newRewardPerBlock The new reward amount per block
    function updateRewardPerBlock(
        uint256 _newRewardPerBlock
    ) external onlyOwner {
        rewardPerBlock = _newRewardPerBlock;
    }

    /// @notice Allows the owner to pause the contract
    function pause() external onlyOwner {
        _pause = true;
    }

    /// @notice Allows the owner to unpause the contract
    function unpause() external onlyOwner {
        _pause = false;
    }

    /// @notice Allows the owner to update the delay period for claiming rewards
    /// @param _newDelayPeriod The new delay period
    function updateDelayPeriod(uint256 _newDelayPeriod) external onlyOwner {
        delayPeriod = _newDelayPeriod;
    }

    /// @notice Allows the owner to update the unbonding period
    /// @param _newUnbondingPeriod The new unbonding period
    function updateUnbondingPeriod(
        uint256 _newUnbondingPeriod
    ) external onlyOwner {
        unbondingPeriod = _newUnbondingPeriod;
    }

    /// @notice Internal function to authorize an upgrade
    /// @dev This function is required by the UUPSUpgradeable contract
    /// @param newImplementation Address of the new implementation
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @notice Returns the version of the contract
    /// @return A string representing the version number
    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
