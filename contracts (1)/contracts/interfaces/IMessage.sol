// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMessage {
    struct AssetMessage {
        uint256 messageId;
        uint256 tokenId;
        address sender;
        string contentURI;
        uint64 sentAt;
        bool active;
    }

    event MessageSent(
        uint256 indexed messageId,
        uint256 indexed tokenId,
        address indexed sender,
        string contentURI
    );

    event MessageDeleted(
        uint256 indexed messageId,
        uint256 indexed tokenId
    );

    function sendMessage(
        uint256 tokenId,
        string calldata contentURI
    ) external returns (uint256);

    function messageOf(
        uint256 messageId
    ) external view returns (AssetMessage memory);

    function messagesOfAsset(
        uint256 tokenId
    ) external view returns (uint256[] memory);

    function deleteMessage(
        uint256 messageId
    ) external;
}