// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Timestamp {
    function hasExpired(uint256 timestamp) internal view returns (bool) {
        return block.timestamp >= timestamp;
    }
}
