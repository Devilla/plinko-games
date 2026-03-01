// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Counter
/// @notice Sample contract for testing Avalanche Fuji tooling.
contract Counter {
    uint256 public count;

    event Incremented(uint256 newCount);
    event Decremented(uint256 newCount);

    function increment() external {
        count += 1;
        emit Incremented(count);
    }

    function decrement() external {
        require(count > 0, "Counter: underflow");
        count -= 1;
        emit Decremented(count);
    }

    function reset() external {
        count = 0;
    }
}
