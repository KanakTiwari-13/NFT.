// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMembershipEcosystem is ERC721, ERC721URIStorage, Ownable {
    
    uint256 private _tokenIdCounter;
    
    // Membership tiers
    enum MembershipTier { Bronze, Silver, Gold }
    
    // NFT metadata structure
    struct NFTMetadata {
        MembershipTier tier;
        uint256 mintDate;
        bool isStaked;
        uint256 stakingStartDate;
        uint256 rewardsAccumulated;
    }
    
    // Mapping from token ID to NFT metadata
    mapping(uint256 => NFTMetadata) public nftMetadata;
    
    // Mapping from owner to membership tier
    mapping(address => MembershipTier) public membershipTier;
    
    // Utility token for rewards (simplified)
    mapping(address => uint256) public utilityTokenBalance;
    
    // Community access mapping
    mapping(address => bool) public communityAccess;
    
    // Events
    event NFTMinted(address indexed to, uint256 indexed tokenId, MembershipTier tier);
    event NFTStaked(uint256 indexed tokenId, address indexed owner);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner);
    event RewardsClaimed(address indexed owner, uint256 amount);
    event CommunityAccessGranted(address indexed member, MembershipTier tier);
    
    constructor() ERC721("NFT Membership Ecosystem", "NFTME") Ownable(msg.sender) {}
    
    // Function 1: Mint Membership NFT
    function mintMembershipNFT(address to, MembershipTier tier, string memory uri) 
        public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        // Set NFT metadata
        nftMetadata[tokenId] = NFTMetadata({
            tier: tier,
            mintDate: block.timestamp,
            isStaked: false,
            stakingStartDate: 0,
            rewardsAccumulated: 0
        });
        
        // Update user's membership tier (highest tier they own)
        if (uint8(tier) > uint8(membershipTier[to])) {
            membershipTier[to] = tier;
        }
        
        // Grant community access
        communityAccess[to] = true;
        
        emit NFTMinted(to, tokenId, tier);
        emit CommunityAccessGranted(to, tier);
        
        return tokenId;
    }
    
    // Function 2: Stake NFT for rewards
    function stakeNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(!nftMetadata[tokenId].isStaked, "NFT is already staked");
        
        nftMetadata[tokenId].isStaked = true;
        nftMetadata[tokenId].stakingStartDate = block.timestamp;
        
        emit NFTStaked(tokenId, msg.sender);
    }
    
    // Function 3: Unstake NFT and claim rewards
    function unstakeNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(nftMetadata[tokenId].isStaked, "NFT is not staked");
        
        // Calculate rewards based on staking duration and tier
        uint256 stakingDuration = block.timestamp - nftMetadata[tokenId].stakingStartDate;
        uint256 dailyReward = getDailyReward(nftMetadata[tokenId].tier);
        uint256 rewards = (stakingDuration * dailyReward) / 1 days;
        
        // Update rewards
        nftMetadata[tokenId].rewardsAccumulated += rewards;
        utilityTokenBalance[msg.sender] += rewards;
        
        // Unstake the NFT
        nftMetadata[tokenId].isStaked = false;
        nftMetadata[tokenId].stakingStartDate = 0;
        
        emit NFTUnstaked(tokenId, msg.sender);
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    // Get daily reward based on membership tier
    function getDailyReward(MembershipTier tier) public pure returns (uint256) {
        if (tier == MembershipTier.Bronze) {
            return 10 * 10**18; // 10 tokens per day
        } else if (tier == MembershipTier.Silver) {
            return 25 * 10**18; // 25 tokens per day
        } else if (tier == MembershipTier.Gold) {
            return 50 * 10**18; // 50 tokens per day
        }
        return 0;
    }
    
    // Calculate pending rewards for a staked NFT
    function getPendingRewards(uint256 tokenId) public view returns (uint256) {
        if (!nftMetadata[tokenId].isStaked) {
            return 0;
        }
        
        uint256 stakingDuration = block.timestamp - nftMetadata[tokenId].stakingStartDate;
        uint256 dailyReward = getDailyReward(nftMetadata[tokenId].tier);
        return (stakingDuration * dailyReward) / 1 days;
    }
    
    // Check if user has community access
    function hasCommunityAccess(address user) public view returns (bool) {
        return communityAccess[user];
    }
    
    // Get user's membership tier
    function getUserMembershipTier(address user) public view returns (MembershipTier) {
        return membershipTier[user];
    }
    
    // Get user's utility token balance
    function getUtilityTokenBalance(address user) public view returns (uint256) {
        return utilityTokenBalance[user];
    }
    
    // Get NFT metadata
    function getNFTMetadata(uint256 tokenId) public view returns (NFTMetadata memory) {
        return nftMetadata[tokenId];
    }
    
    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
