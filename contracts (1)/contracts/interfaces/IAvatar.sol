// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAvatar {
    enum AvatarState {
        None,
        Idle,
        Busy,
        Offline,
        Online
    }

    struct AvatarProfile {
        address owner;
        string avatarURI;
        AvatarState state;
        bool active;
    }

    event AvatarCreated(uint256 indexed avatarId, address indexed owner, string avatarURI);
    event AvatarURIUpdated(uint256 indexed avatarId, string avatarURI);
    event AvatarStateChanged(uint256 indexed avatarId, AvatarState oldState, AvatarState newState);
    event AvatarDeactivated(uint256 indexed avatarId);
    event AvatarReactivated(uint256 indexed avatarId);

    function createAvatar(address owner, string calldata avatarURI) external returns (uint256);

    function avatarProfileOf(uint256 avatarId) external view returns (AvatarProfile memory);

    function avatarOwnerOf(uint256 avatarId) external view returns (address);

    function avatarURIOf(uint256 avatarId) external view returns (string memory);

    function avatarStateOf(uint256 avatarId) external view returns (AvatarState);

    function isAvatarActive(uint256 avatarId) external view returns (bool);

    function updateAvatarURI(uint256 avatarId, string calldata newAvatarURI) external;

    function setAvatarState(uint256 avatarId, AvatarState newState) external;

    function deactivateAvatar(uint256 avatarId) external;

    function reactivateAvatar(uint256 avatarId) external;
}