// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDataTypes} from "./interfaces/IDataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Timestamp} from "./libs/Timestamp.sol";

contract VestingWallet is IVesting {
    using Timestamp for uint256;
    using SafeERC20 for IERC20;

    uint256 constant SECONDS_PER_YEAR = 365 days;

    IERC20 public immutable reward;
    address public immutable staking;
    address public immutable owner;
    IDataTypes.VestingRecord[] public vested;

    constructor(
        address _staking,
        IERC20 _reward,
        address _owner
    ) {
        staking = _staking;
        reward = _reward;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "vesting/not-owner");
        _;
    }

    modifier onlyStaking() {
        require(msg.sender == staking, "vesting/not-staking");
        _;
    }

    function vest(uint256 amount) external onlyStaking {
        require(amount > 0, "vesting/invalid-amount");
        reward.safeTransferFrom(msg.sender, address(this), amount);
        vested.push(IDataTypes.VestingRecord(amount, block.timestamp + SECONDS_PER_YEAR)); // create records
        emit VestingStarted(owner, amount);
    }

    function claim(uint256 index) external onlyOwner {
        require(vested[index].unlockTimestamp.hasExpired(), "vesting/claim-not-eligible");
        _claim(index);
    }

    function claimAll() external onlyOwner {
        IDataTypes.VestingRecord[] memory records = vested;
        require(records.length > 0, "vesting/no-records");

        for (uint256 idx = records.length; idx > 0; idx--) {
            if (records[idx - 1].unlockTimestamp.hasExpired()) {
                _claim(idx - 1);
            }
        }
    }

    function getVestingRecordsCount() external view returns (uint256) {
        return vested.length;
    }

    function getVestingRecords() external view returns (IDataTypes.VestingState[] memory data) {
        data = new IDataTypes.VestingState[](vested.length);
        for (uint256 index = 0; index < vested.length; index++) {
            data[index] = IDataTypes.VestingState(
                uint32(vested[index].unlockTimestamp - SECONDS_PER_YEAR),
                uint32(vested[index].unlockTimestamp),
                vested[index].amount,
                index
            );
        }
        return data;
    }

    function _claim(uint256 index) internal {
        IDataTypes.VestingRecord memory record = vested[index];
        reward.safeTransfer(owner, record.amount);
        _remove(index);
        emit VestingEnded(owner, record.amount);
    }

    function _remove(uint256 index) internal {
        uint256 length = vested.length;
        require(index < length, "vesting/array-out-of-bounds");

        // remove element from array
        if (index != length - 1) {
            vested[index] = vested[length - 1];
        }
        vested.pop();
    }
}
