// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Japanese Study Achievement Registry
/// @notice Minimal registry for anchoring a learner's achievement hash on-chain.
/// @dev The Flutter app currently generates deterministic credential hashes locally;
///      a wallet/backend can call registerAchievement when the blockchain layer is enabled.
contract JapaneseStudyAchievementRegistry {
    struct Achievement {
        bytes32 learnerId;
        bytes32 achievementHash;
        uint64 issuedAt;
        string credentialId;
    }

    mapping(address => Achievement[]) private achievements;

    event AchievementRegistered(
        address indexed learner,
        bytes32 indexed learnerId,
        bytes32 indexed achievementHash,
        string credentialId,
        uint64 issuedAt
    );

    function registerAchievement(
        bytes32 learnerId,
        bytes32 achievementHash,
        string calldata credentialId
    ) external {
        require(achievementHash != bytes32(0), "empty achievement hash");
        achievements[msg.sender].push(
            Achievement({
                learnerId: learnerId,
                achievementHash: achievementHash,
                issuedAt: uint64(block.timestamp),
                credentialId: credentialId
            })
        );
        emit AchievementRegistered(
            msg.sender,
            learnerId,
            achievementHash,
            credentialId,
            uint64(block.timestamp)
        );
    }

    function getAchievementCount(address learner) external view returns (uint256) {
        return achievements[learner].length;
    }

    function getAchievement(address learner, uint256 index) external view returns (Achievement memory) {
        return achievements[learner][index];
    }
}
