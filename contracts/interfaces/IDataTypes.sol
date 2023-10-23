// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDataTypes {
    struct StakingRecord {
        uint256 amount;
        uint256 unlockTimestamp;
        uint256 virtualAmount;
        uint256 lastGlobalMultiplierValue;
    }

    struct VestingRecord {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    struct VestingState {
        uint32 startTime;
        uint32 endTime;
        uint256 amount;
        uint256 index;
    }

    struct StakingState {
        address asset;
        uint8 period;
        uint32 startTime;
        uint32 endTime;
        uint256 amountStaked;
        uint256 amountClaimable;
        uint256 index;
    }
}
