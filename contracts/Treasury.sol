// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is ITreasury, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant WITHDRAWAL_FACTOR_BASE = 10**9;

    IERC20 public asset;
    IERC20 public reward;

    uint256 public withdrawalFactorPerBlock;
    uint256 public lastWithdrawalBlock;

    constructor(
        IERC20 _asset,
        IERC20 _reward,
        uint256 _withdrawalFactor
    ) Ownable(msg.sender) {
        asset = _asset;
        reward = _reward;
        require(_withdrawalFactor < WITHDRAWAL_FACTOR_BASE, "Treasury: withdrawal factor must be less than 1");
        withdrawalFactorPerBlock = _withdrawalFactor;
        lastWithdrawalBlock = block.number;
    }

    /// @notice Returns the address of the asset token.
    /// @param _recipient The address of the recipient.
    /// @param _amount The amount of the asset token to withdraw.
    function withdrawReward(
        address _recipient,
        uint256 _amount
    )
        external
        onlyOwner
    {
        uint256 balance = reward.balanceOf(address(this));
        if (_amount >= balance) revert InsufficientRewardBalance();
        reward.safeTransfer(_recipient, _amount);
    }

    /// @notice Must be called only by the contract's owner.
    ///         If this function is called within the same block as the last withdrawal,
    ///         it returns 0 and no withdrawal occurs.
    /// @return uint256 The amount withdrawn by the owner.
    function withdrawInterest()
        external
        onlyOwner
        returns (uint256)
    {
        if (block.number == lastWithdrawalBlock) {
            return 0;
        }
        uint256 blocksPassed = block.number - lastWithdrawalBlock;
        uint256 interestFactor = withdrawalFactorPerBlock ** blocksPassed;
        uint256 availableAmount = reward.balanceOf(address(this)) * interestFactor / WITHDRAWAL_FACTOR_BASE;
        uint256 amountToWithdraw = (availableAmount * interestFactor) / (WITHDRAWAL_FACTOR_BASE * interestFactor);
        reward.safeTransfer(msg.sender, amountToWithdraw);
        return amountToWithdraw;
    }
}
