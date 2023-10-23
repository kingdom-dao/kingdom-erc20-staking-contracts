// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStaking {
    event Deposit(
        address indexed user,
        address indexed asset,
        uint8 indexed period,
        uint256 amount
    );
    event Withdrawal(
        address indexed user,
        address indexed asset,
        uint8 indexed period,
        uint256 amount
    );
    event InterestClaimed(address indexed user, address indexed wallet, uint256 amount);

    event TreasuryCreated(address indexed asset, address indexed treasury, uint256 withdrawFactor);
    event WalletCreated(address indexed user, address indexed wallet);
}
