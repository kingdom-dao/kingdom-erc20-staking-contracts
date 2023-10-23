// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasury {
    error InsufficientRewardBalance();

    function withdrawReward(
        address _recipient,
        uint256 _amount
    ) external;
    function withdrawInterest()
        external returns (uint256);
}
