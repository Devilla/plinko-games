// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Betting.sol";

/// @notice Test helper contract for Betting, mirroring the Foundry test helper
contract BettingTestHelper is Betting {
  constructor() Betting(address(0), address(0), bytes32(0), 0) {}

  /// @notice Override placeBet to avoid LINK requirement and VRF call
  function placeBet(
    Game game,
    bytes calldata data
  ) external payable override returns (bytes32 requestId) {
    require(msg.value > 0, "must send bet amount");
    // create fake requestId deterministically
    requestId =
      keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp));

    bets[requestId] = Bet({
      player: msg.sender,
      amount: msg.value,
      game: game,
      data: data,
      resolved: false
    });

    emit BetPlaced(requestId, msg.sender, msg.value, game);
  }

  /// @notice Expose manual fulfill for tests
  function fulfill(bytes32 requestId, uint256 randomness) public {
    _manualFulfill(requestId, randomness);
  }
}

