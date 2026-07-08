// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IAvatar.sol";

contract Avatar is IAvatar {
    uint256 public nextAvatarId = 1;

    mapping(uint256 => AvatarProfile) private avatarProfiles;

    modifier avatarExists(uint256 avatarId) {
        require(avatarProfiles[avatarId].owner != address(0), "Avatar does not exist");
        _;
    }

    modifier onlyAvatarOwner(uint256 avatarId) {
        require(avatarProfiles[avatarId].owner == msg.sender, "Not avatar owner");
        _;
    }

    function createAvatar(
        address owner,
        string calldata avatarURI
    ) external override returns (uint256) {
        require(owner != address(0), "Invalid owner");
        require(bytes(avatarURI).length > 0, "Empty avatar URI");

        uint256 avatarId = nextAvatarId;
        nextAvatarId++;

        avatarProfiles[avatarId] = AvatarProfile({
            owner: owner,
            avatarURI: avatarURI,
            state: AvatarState.Idle,
            active: true
        });

        emit AvatarCreated(avatarId, owner, avatarURI);
        emit AvatarStateChanged(avatarId, AvatarState.None, AvatarState.Idle);

        return avatarId;
    }

    function avatarProfileOf(
        uint256 avatarId
    ) external view override avatarExists(avatarId) returns (AvatarProfile memory) {
        return avatarProfiles[avatarId];
    }

    function avatarOwnerOf(
        uint256 avatarId
    ) external view override avatarExists(avatarId) returns (address) {
        return avatarProfiles[avatarId].owner;
    }

    function avatarURIOf(
        uint256 avatarId
    ) external view override avatarExists(avatarId) returns (string memory) {
        return avatarProfiles[avatarId].avatarURI;
    }

    function avatarStateOf(
        uint256 avatarId
    ) external view override avatarExists(avatarId) returns (AvatarState) {
        return avatarProfiles[avatarId].state;
    }

    function isAvatarActive(
        uint256 avatarId
    ) external view override avatarExists(avatarId) returns (bool) {
        return avatarProfiles[avatarId].active;
    }

    function updateAvatarURI(
        uint256 avatarId,
        string calldata newAvatarURI
    ) external override avatarExists(avatarId) onlyAvatarOwner(avatarId) {
        require(bytes(newAvatarURI).length > 0, "Empty avatar URI");
        require(avatarProfiles[avatarId].active, "Avatar is not active");

        avatarProfiles[avatarId].avatarURI = newAvatarURI;

        emit AvatarURIUpdated(avatarId, newAvatarURI);
    }

    function setAvatarState(
        uint256 avatarId,
        AvatarState newState
    ) external override avatarExists(avatarId) onlyAvatarOwner(avatarId) {
        require(avatarProfiles[avatarId].active, "Avatar is not active");
        require(newState != AvatarState.None, "Invalid avatar state");

        AvatarState oldState = avatarProfiles[avatarId].state;
        require(oldState != newState, "Avatar already in this state");

        avatarProfiles[avatarId].state = newState;

        emit AvatarStateChanged(avatarId, oldState, newState);
    }

    function deactivateAvatar(
        uint256 avatarId
    ) external override avatarExists(avatarId) onlyAvatarOwner(avatarId) {
        require(avatarProfiles[avatarId].active, "Avatar already inactive");

        avatarProfiles[avatarId].active = false;

        emit AvatarDeactivated(avatarId);
    }

    function reactivateAvatar(
        uint256 avatarId
    ) external override avatarExists(avatarId) onlyAvatarOwner(avatarId) {
        require(!avatarProfiles[avatarId].active, "Avatar already active");

        avatarProfiles[avatarId].active = true;

        emit AvatarReactivated(avatarId);
    }
}