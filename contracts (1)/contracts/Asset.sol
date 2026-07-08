// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "contracts/interfaces/IAsset.sol";
import "contracts/interfaces/IAvatar.sol";


contract Asset is IAsset {
    uint256 public nextTokenId = 1;

    IAvatar public avatarContract;

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApprovals;

    mapping(uint256 => AssetProfile) private assetProfiles;
    mapping(uint256 => AssetState) private assetStates;

    mapping(uint256 => UsageInfo) private usageInfos;
    mapping(uint256 => EquipInfo) private equipInfos;

    // tokenId => worldId => WorldProfile
    mapping(uint256 => mapping(string => WorldProfile)) private worldProfiles;

    constructor(address avatarContractAddress) {
        require(
            avatarContractAddress != address(0),
            "Avatar contract is zero address"
        );

        avatarContract = IAvatar(avatarContractAddress);
    }

    modifier assetExists(uint256 tokenId) {
        require(owners[tokenId] != address(0), "Asset does not exist");
        _;
    }

    modifier onlyAssetOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not asset owner");
        _;
    }

    // Min ERC-721 
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "Zero address");
        return balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        assetExists(tokenId)
        returns (address)
    {
        return owners[tokenId];
    }

    function approve(address to, uint256 tokenId)
        external
        override
        assetExists(tokenId)
    {
        address owner = ownerOf(tokenId);

        require(msg.sender == owner, "Only owner can approve");
        require(to != owner, "Cannot approve owner");

        tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        assetExists(tokenId)
        returns (address)
    {
        return tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId)
        external
        override
        assetExists(tokenId)
    {
        address owner = ownerOf(tokenId);

        require(owner == from, "From is not owner");
        require(to != address(0), "Transfer to zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        _clearApproval(tokenId);
        _clearUsage(tokenId);
        _clearEquip(tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;

        assetStates[tokenId] = AssetState.Idle;

        emit Transfer(from, to, tokenId);
    }

    function createAsset(
        address to,
        string calldata assetClass,
        string calldata slotType,
        string calldata fingerprint,
        string calldata metadataURI,
        string calldata compatibilityURI
    ) external override returns (uint256) {
        require(to != address(0), "Mint to zero address");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        owners[tokenId] = to;
        balances[to] += 1;

        assetProfiles[tokenId] = AssetProfile({
            assetClass: assetClass,
            slotType: slotType,
            fingerprint: fingerprint,
            metadataURI: metadataURI,
            compatibilityURI: compatibilityURI
        });

        assetStates[tokenId] = AssetState.Idle;

        emit Transfer(address(0), to, tokenId);
        emit AssetCreated(tokenId, to);

        return tokenId;
    }

    function assetProfileOf(uint256 tokenId)
        external
        view
        override
        assetExists(tokenId)
        returns (AssetProfile memory)
    {
        return assetProfiles[tokenId];
    }

    function assetStateOf(uint256 tokenId)
        external
        view
        override
        assetExists(tokenId)
        returns (AssetState)
    {
        return assetStates[tokenId];
    }


    function setUser(
        uint256 tokenId,
        address user,
        uint256 avatarId,
        uint64 expires
    ) external override assetExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(user != address(0), "User is zero address");
        require(expires > block.timestamp, "Expiration must be future");
        require(assetStates[tokenId] != AssetState.Equipped, "Asset already equipped");

        _validateAvatarForUser(avatarId, user);

        usageInfos[tokenId] = UsageInfo({
            user: user,
            avatarId: avatarId,
            expires: expires,
            active: true
        });

        assetStates[tokenId] = AssetState.InUse;

        emit UserUpdated(tokenId, user, avatarId, expires);
    }

    function userOf(uint256 tokenId)
        public
        view
        override
        assetExists(tokenId)
        returns (address)
    {
        UsageInfo memory info = usageInfos[tokenId];

        if (!info.active) {
            return address(0);
        }

        if (info.expires < block.timestamp) {
            return address(0);
        }

        return info.user;
    }

    function userExpires(uint256 tokenId)
        external
        view
        override
        assetExists(tokenId)
        returns (uint64)
    {
        return usageInfos[tokenId].expires;
    }

    function clearUser(uint256 tokenId)
        external
        override
        assetExists(tokenId)
    {
        address currentUser = userOf(tokenId);

        require(
            _isApprovedOrOwner(msg.sender, tokenId) || msg.sender == currentUser,
            "Not allowed to clear user"
        );

        _clearUsage(tokenId);

        if (assetStates[tokenId] == AssetState.InUse) {
            assetStates[tokenId] = AssetState.Idle;
        }

        emit UserCleared(tokenId);
    }


    function equip(uint256 tokenId, uint256 avatarId)
        external
        override
        assetExists(tokenId)
    {
        address currentUser = userOf(tokenId);

        require(
            _isApprovedOrOwner(msg.sender, tokenId) || msg.sender == currentUser,
            "Not allowed to equip"
        );

        require(assetStates[tokenId] != AssetState.Equipped, "Already equipped");

        _validateAvatarForUser(avatarId, msg.sender);

        AssetProfile memory profile = assetProfiles[tokenId];

        equipInfos[tokenId] = EquipInfo({
            avatarId: avatarId,
            slotType: profile.slotType,
            equippedAt: uint64(block.timestamp),
            equipped: true
        });

        assetStates[tokenId] = AssetState.Equipped;

        emit Equipped(tokenId, avatarId, profile.slotType);
    }

    function unequip(uint256 tokenId)
        external
        override
        assetExists(tokenId)
    {
        require(equipInfos[tokenId].equipped, "Not equipped");

        address currentUser = userOf(tokenId);
        uint256 equippedAvatarId = equipInfos[tokenId].avatarId;
        address equippedAvatarOwner = avatarContract.avatarOwnerOf(equippedAvatarId);

        require(
            _isApprovedOrOwner(msg.sender, tokenId) ||
                msg.sender == currentUser ||
                msg.sender == equippedAvatarOwner,
            "Not allowed to unequip"
        );

        uint256 avatarId = equipInfos[tokenId].avatarId;

        _clearEquip(tokenId);

        if (userOf(tokenId) != address(0)) {
            assetStates[tokenId] = AssetState.InUse;
        } else {
            assetStates[tokenId] = AssetState.Idle;
        }

        emit Unequipped(tokenId, avatarId);
    }

    function equipInfoOf(uint256 tokenId)
        external
        view
        override
        assetExists(tokenId)
        returns (EquipInfo memory)
    {
        return equipInfos[tokenId];
    }

    function setWorldProfile(
        uint256 tokenId,
        string calldata worldId,
        bool supported,
        string calldata profileURI
    )
        external override assetExists(tokenId) onlyAssetOwner(tokenId)
    {
        worldProfiles[tokenId][worldId] = WorldProfile({
            worldId: worldId,
            supported: supported,
            profileURI: profileURI
        });

        emit WorldProfileSet(tokenId, worldId, supported, profileURI);
    }

    function worldProfileOf(
        uint256 tokenId,
        string calldata worldId
    )
        external
        view
        override
        assetExists(tokenId)
        returns (WorldProfile memory)
    {
        return worldProfiles[tokenId][worldId];
    }

    function supportsWorld(
        uint256 tokenId,
        string calldata worldId
    )
        external
        view
        override
        assetExists(tokenId)
        returns (bool)
    {
        return worldProfiles[tokenId][worldId].supported;
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);

        return (
            spender == owner ||
            getApproved(tokenId) == spender
        );
    }

    function _validateAvatarForUser(uint256 avatarId, address user)
        internal
        view
    {
        require(avatarContract.isAvatarActive(avatarId), "Avatar is not active");
        require(
            avatarContract.avatarOwnerOf(avatarId) == user,
            "User does not own avatar"
        );
    }

    function _clearApproval(uint256 tokenId) internal {
        if (tokenApprovals[tokenId] != address(0)) {
            tokenApprovals[tokenId] = address(0);
        }
    }

    function _clearUsage(uint256 tokenId) internal {
        delete usageInfos[tokenId];
    }

    function _clearEquip(uint256 tokenId) internal {
        delete equipInfos[tokenId];
    }
}