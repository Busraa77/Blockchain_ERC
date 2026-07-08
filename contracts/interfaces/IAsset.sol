// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAsset{ 
    enum AssetState {
        None,
        Idle,
        InUse,
        Equipped
    }

    struct AssetProfile {
        string assetClass;
        string slotType;
        string fingerprint;
        string metadataURI;
        string compatibilityURI;
    }

    struct UsageInfo {
        address user;
        uint256 avatarId;
        uint64 expires;
        bool active;
    }

    struct EquipInfo {
        uint256 avatarId;
        string slotType;
        uint64 equippedAt;
        bool equipped;
    }

    struct WorldProfile {
        string worldId;
        bool supported;
        string profileURI;
    }

    // Minimum ERC-721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event AssetCreated(uint256 indexed tokenId, address indexed owner);
    event UserUpdated(uint256 indexed tokenId,address indexed user,uint256 indexed avatarId,uint64 expires);
    event UserCleared(uint256 indexed tokenId);
    event Equipped(uint256 indexed tokenId, uint256 indexed avatarId, string slotType);
    event Unequipped(uint256 indexed tokenId, uint256 indexed avatarId);
    event WorldProfileSet(uint256 indexed tokenId,string worldId,bool supported,string profileURI);    
    
    // Min ERC-721 
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
   
    function createAsset(address to,string calldata assetClass,string calldata slotType,string calldata fingerprint,
    string calldata metadataURI,string calldata compatibilityURI) external returns (uint256);

    function assetProfileOf(uint256 tokenId) external view returns (AssetProfile memory);

    function assetStateOf(uint256 tokenId) external view returns (AssetState);

    // ERC-4907 
    function setUser(uint256 tokenId,address user,uint256 avatarId,uint64 expires) external;

    function userOf(uint256 tokenId) external view returns (address);

    function userExpires(uint256 tokenId) external view returns (uint64);

    function clearUser(uint256 tokenId) external;

    function equip(uint256 tokenId, uint256 avatarId) external;

    function unequip(uint256 tokenId) external;

    function equipInfoOf(uint256 tokenId) external view returns (EquipInfo memory);

    function setWorldProfile(uint256 tokenId,string calldata worldId,bool supported,string calldata profileURI) external;

    function worldProfileOf(uint256 tokenId,string calldata worldId) external view returns (WorldProfile memory);

    function supportsWorld(uint256 tokenId,string calldata worldId) external view returns (bool);
}