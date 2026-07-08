// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/interfaces/IMessage.sol";
import "contracts/interfaces/IAsset.sol";

contract MessageExtension is IMessage {
    uint256 public nextMessageId = 1;

    IAsset public assetContract;

    mapping(uint256 => AssetMessage) private messages;
    mapping(uint256 => uint256[]) private assetMessages;

    constructor(address assetContractAddress) {
        require(
            assetContractAddress != address(0),
            "Asset contract is zero address"
        );

        assetContract = IAsset(assetContractAddress);
    }

    function sendMessage(
        uint256 tokenId,
        string calldata contentURI
    ) external override returns (uint256) {
        require(bytes(contentURI).length > 0, "Empty content URI");

        address assetOwner = assetContract.ownerOf(tokenId);
        address assetUser = assetContract.userOf(tokenId);

        require(
            msg.sender == assetOwner || msg.sender == assetUser,
            "Not allowed to message"
        );

        uint256 messageId = nextMessageId;
        nextMessageId++;

        messages[messageId] = AssetMessage({
            messageId: messageId,
            tokenId: tokenId,
            sender: msg.sender,
            contentURI: contentURI,
            sentAt: uint64(block.timestamp),
            active: true
        });

        assetMessages[tokenId].push(messageId);

        emit MessageSent(messageId, tokenId, msg.sender, contentURI);

        return messageId;
    }

    function messageOf(
        uint256 messageId
    ) external view override returns (AssetMessage memory) {
        require(messages[messageId].active, "Message does not exist");
        return messages[messageId];
    }

    function messagesOfAsset(
        uint256 tokenId
    ) external view override returns (uint256[] memory) {
        assetContract.ownerOf(tokenId);
        return assetMessages[tokenId];
    }

    function deleteMessage(
        uint256 messageId
    ) external override {
        require(messages[messageId].active, "Message does not exist");
        require(
            messages[messageId].sender == msg.sender,
            "Only sender can delete"
        );

        uint256 tokenId = messages[messageId].tokenId;

        messages[messageId].active = false;

        emit MessageDeleted(messageId, tokenId);
    }
}