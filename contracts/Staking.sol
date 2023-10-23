// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDataTypes} from "./interfaces/IDataTypes.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Timestamp} from "./libs/Timestamp.sol";
import {Treasury} from "./Treasury.sol";
import {VestingWallet} from "./Vesting.sol";

error InvalidAmount();

contract Staking is IStaking, Ownable {
    using SafeERC20 for IERC20;
    using Timestamp for uint256;

    uint256 public constant SECONDS_IN_WEEK = 7 days;
    uint256 public constant ACCUMULATOR_BASE = 10**15;

    IERC20 public reward;

    mapping(IERC20 => address) public treasuries; // underlying asset => treasury
    mapping(IERC20 => uint256) public totalVirtualAmount; // underlying asset => total virtual amount
    mapping(IERC20 => uint256) public totalLockedValue; // underlying asset => total Locked Value
    mapping(IERC20 => uint256) public globalInterestAccumulator; // underlying asset => global interest accumulator
    mapping(address => mapping(IERC20 => mapping(uint8 => IDataTypes.StakingRecord[])))
        public staked; // user => asset => period => record
    mapping(address => uint256) public stakedCount;

    constructor(
        IERC20 _reward
    ) Ownable(msg.sender) {
        reward = _reward;
    }

    function getTreasuryAddress(
        address _asset,
        uint256 _withdrawFactor
    )
        external
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                keccak256(abi.encodePacked(address(_asset))),
                keccak256(
                    abi.encodePacked(
                        type(Treasury).creationCode,
                        abi.encode(address(_asset), reward, _withdrawFactor)
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }

    function getWalletAddress(address _owner) external view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                keccak256(abi.encodePacked(reward, _owner)),
                keccak256(
                    abi.encodePacked(
                        type(VestingWallet).creationCode,
                        abi.encode(address(this), reward, _owner)
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }

    function whitelist(IERC20 _asset, uint256 _withdrawFactor) external onlyOwner {
        require(treasuries[_asset] == address(0), "staking/asset-exists");
        bytes memory bytecode = abi.encodePacked(
            type(Treasury).creationCode,
            abi.encode(_asset, reward, _withdrawFactor)
        );
        bytes32 salt = keccak256(abi.encodePacked(_asset));
        address treasury;
        assembly {
            treasury := create2(0, add(bytecode, 32), mload(bytecode), salt)

            if iszero(extcodesize(treasury)) {
                revert(0, 0)
            }
        }
        treasuries[_asset] = treasury;
        emit TreasuryCreated(address(_asset), treasury, _withdrawFactor);
    }

    function isSupportedPeriod(uint8 _weeks) public pure returns (bool) {
        return _weeks >= 1 && _weeks <= 52;
    }

    function calculateVirtualAmount(
        uint256 _amount,
        uint8 _period
    )
        public
        pure
        returns (uint256)
    {
        return _amount * _period;
    }

    function deposit(
        IERC20 _asset,
        uint8 _period,
        uint256 _amount
    )
        external
    {
        require(_amount > 0, "staking/invalid-amount");
        _asset.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 virtualAmount = calculateVirtualAmount(_amount, _period);
        _updateGlobalAccumulatorsWithdrawInterest(_asset, virtualAmount);
        totalLockedValue[_asset] = totalLockedValue[_asset] + _amount;
        staked[msg.sender][_asset][_period].push(
            IDataTypes.StakingRecord(
                _amount,
                block.timestamp + (_period * SECONDS_IN_WEEK),
                virtualAmount,
                globalInterestAccumulator[_asset]
            )
        );
        stakedCount[msg.sender]++;
        emit Deposit(msg.sender, address(_asset), _period, _amount);
    }

    function _updateGlobalAccumulatorsWithdrawInterest(IERC20 asset, uint256 virtualAmount)
        internal
    {
        Treasury treasury = Treasury(treasuries[asset]);
        uint256 assetTotalVirtualAmount = totalVirtualAmount[asset];
        if (assetTotalVirtualAmount > 0) {
            // wait for accruing interest till staking contract is not empty
            uint256 interestAccrued = treasury.withdrawInterest();
            globalInterestAccumulator[asset] =
                globalInterestAccumulator[asset] +
                (interestAccrued * ACCUMULATOR_BASE) /
                assetTotalVirtualAmount;
        }
        totalVirtualAmount[asset] = assetTotalVirtualAmount + virtualAmount;
    }

    function _withdrawInterest(VestingWallet wallet, uint256 amount) internal {
        if (amount > 0) {
            wallet.vest(amount);
            emit InterestClaimed(msg.sender, address(wallet), amount);
        }
    }
}
