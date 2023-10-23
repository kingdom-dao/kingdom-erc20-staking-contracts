// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVesting {
    event VestingStarted(address indexed user, uint256 amount);
    event VestingEnded(address indexed user, uint256 amount);
}
