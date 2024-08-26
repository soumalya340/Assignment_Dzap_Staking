# Solidity API

## DzapNFTStaking

This contract allows users to stake NFTs and earn ERC20 token rewards

_This contract is upgradeable and uses OpenZeppelin's upgradeable contracts_

### nftContract

```solidity
contract IERC721 nftContract
```

### rewardToken

```solidity
contract IERC20 rewardToken
```

### rewardPerBlock

```solidity
uint256 rewardPerBlock
```

### delayPeriod

```solidity
uint256 delayPeriod
```

### unbondingPeriod

```solidity
uint256 unbondingPeriod
```

### AssetInfo

Struct to store information about staked assets

```solidity
struct AssetInfo {
  address owner;
  uint256 lastblock;
  uint256 unbondingEndTime;
  uint256 untstakingEndBlock;
  enum DzapNFTStaking.AssetStatus status;
}
```

### AssetStatus

Enum to represent the status of an asset

```solidity
enum AssetStatus {
  NOTSTAKED,
  STAKED,
  UNSTAKING_IN_PROGRESS,
  UNSTAKED
}
```

### stakedNFTs

```solidity
mapping(uint256 => struct DzapNFTStaking.AssetInfo) stakedNFTs
```

Mapping of token IDs to their staking information

### lastClaimTimestamp

```solidity
mapping(address => uint256) lastClaimTimestamp
```

Mapping of staker addresses to their last reward claim timestamp

### whenNotpaused

```solidity
modifier whenNotpaused()
```

Modifier to check if the contract is not paused

### onlywhenTokenOwner

```solidity
modifier onlywhenTokenOwner(uint256 tokenId)
```

Modifier to check if the caller is the owner of the token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token |

### NFTStaked

```solidity
event NFTStaked(address user, uint256 tokenId)
```

Emitted when an NFT is staked

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user who staked the NFT |
| tokenId | uint256 | The ID of the staked NFT |

### NFTUnstaked

```solidity
event NFTUnstaked(address user, uint256 tokenId)
```

Emitted when an NFT is unstaked

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user who unstaked the NFT |
| tokenId | uint256 | The ID of the unstaked NFT |

### RewardsClaimed

```solidity
event RewardsClaimed(address user, uint256 amount)
```

Emitted when rewards are claimed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user who claimed rewards |
| amount | uint256 | The amount of rewards claimed |

### NFTWithdrawn

```solidity
event NFTWithdrawn(address user, uint256 tokenId)
```

Emitted when an NFT is withdrawn

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user who withdrew the NFT |
| tokenId | uint256 | The ID of the withdrawn NFT |

### initialize

```solidity
function initialize() public
```

Initializes the contract

_This function is called once when the contract is deployed_

### setContractData

```solidity
function setContractData(address _nftContract, address _rewardToken, uint256 _rewardPerBlock, uint256 _delayPeriod, uint256 _unbondingPeriod) external
```

Sets the main contract data

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _nftContract | address | Address of the NFT contract |
| _rewardToken | address | Address of the reward token contract |
| _rewardPerBlock | uint256 | Amount of reward tokens given per block |
| _delayPeriod | uint256 | Delay period for claiming rewards |
| _unbondingPeriod | uint256 | Period for unbonding staked NFTs |

### stakeNFT

```solidity
function stakeNFT(uint256 tokenId) external
```

Allows a user to stake an NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the NFT to stake |

### unstakeNFT

```solidity
function unstakeNFT(uint256 tokenId) external
```

Allows a user to initiate the unstaking process for an NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the NFT to unstake |

### withdrawNFT

```solidity
function withdrawNFT(uint256 tokenId) external
```

Allows a user to withdraw their unstaked NFT after the unbonding period

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the NFT to withdraw |

### claimRewards

```solidity
function claimRewards(uint256 tokenId) external
```

Allows a user to claim rewards for a staked NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the NFT for which to claim rewards |

### updateRewardPerBlock

```solidity
function updateRewardPerBlock(uint256 _newRewardPerBlock) external
```

Allows the owner to update the reward per block

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newRewardPerBlock | uint256 | The new reward amount per block |

### pause

```solidity
function pause() external
```

Allows the owner to pause the contract

### unpause

```solidity
function unpause() external
```

Allows the owner to unpause the contract

### updateDelayPeriod

```solidity
function updateDelayPeriod(uint256 _newDelayPeriod) external
```

Allows the owner to update the delay period for claiming rewards

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newDelayPeriod | uint256 | The new delay period |

### updateUnbondingPeriod

```solidity
function updateUnbondingPeriod(uint256 _newUnbondingPeriod) external
```

Allows the owner to update the unbonding period

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newUnbondingPeriod | uint256 | The new unbonding period |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

Internal function to authorize an upgrade

_This function is required by the UUPSUpgradeable contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newImplementation | address | Address of the new implementation |

### version

```solidity
function version() public pure virtual returns (string)
```

Returns the version of the contract

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | A string representing the version number |

## MockERC20

### constructor

```solidity
constructor() public
```

### mint

```solidity
function mint(address to, uint256 amount) public
```

## MockERC721

### constructor

```solidity
constructor() public
```

### mint

```solidity
function mint(address to) public
```

## MyToken

### constructor

```solidity
constructor(address initialOwner) public
```

### mint

```solidity
function mint(address to, uint256 amount) public
```

