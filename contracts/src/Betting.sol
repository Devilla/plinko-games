// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import 'chainlink/v0.8/VRFConsumerBase.sol';
import './GameLibrary.sol';

/// @title Casino Betting with VRF randomness
/// @notice Supports multiple games resolved via Chainlink VRF
contract Betting is VRFConsumerBase {
  enum Game {
    Roulette,
    Dice,
    Limbo,
    RouletteEvenMoney
  }

  struct Bet {
    address player;
    uint256 amount; // wei
    Game game;
    bytes data; // encoded parameters (e.g. selected number for roulette)
    bool resolved;
  }

  mapping(bytes32 => Bet) public bets;

  bytes32 internal keyHash;
  uint256 internal fee;

  event BetPlaced(
    bytes32 indexed requestId,
    address indexed player,
    uint256 amount,
    Game game
  );
  event BetResolved(
    bytes32 indexed requestId,
    address indexed player,
    uint256 payout,
    bytes resultData
  );

  constructor(
    address vrfCoordinator,
    address linkToken,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(vrfCoordinator, linkToken) {
    keyHash = _keyHash;
    fee = _fee;
  }

  /// @notice testing helper to invoke randomness callback without LINK
  function _manualFulfill(bytes32 requestId, uint256 randomness) internal {
    fulfillRandomness(requestId, randomness);
  }

  /// @notice Place a bet on a supported game
  /// @param game which game to play
  /// @param data encoded game-specific parameters
  function placeBet(
    Game game,
    bytes calldata data
  ) external payable virtual returns (bytes32 requestId) {
    require(msg.value > 0, 'must send bet amount');
    require(LINK.balanceOf(address(this)) >= fee, 'not enough LINK');

    requestId = requestRandomness(keyHash, fee);
    bets[requestId] = Bet({
      player: msg.sender,
      amount: msg.value,
      game: game,
      data: data,
      resolved: false
    });

    emit BetPlaced(requestId, msg.sender, msg.value, game);
  }

  /// @dev Chainlink VRF callback
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  ) internal override {
    Bet storage bet = bets[requestId];
    require(bet.player != address(0), 'unknown bet');
    require(!bet.resolved, 'already resolved');

    uint256 payout = 0;
    bytes memory resultData;

    if (bet.game == Game.Roulette) {
      (uint8 winningNumber, uint256 multiplier) = GameLibrary.rouletteResult(
        abi.decode(bet.data, (uint8)),
        randomness
      );
      payout = multiplier > 0 ? bet.amount * multiplier : 0;
      resultData = abi.encode(winningNumber, multiplier);
    } else if (bet.game == Game.Dice) {
      (uint8 target, bool isAbove) = abi.decode(bet.data, (uint8, bool));
      (uint256 result, uint256 multiplier) = GameLibrary.diceResult(
        target,
        isAbove,
        randomness
      );
      // multiplier is percent*100, so divide by 100 to scale
      payout = multiplier > 0 ? (bet.amount * multiplier) / 100 : 0;

      resultData = abi.encode(result, multiplier);
    } else if (bet.game == Game.Limbo) {
      uint256 crashPoint = GameLibrary.limboResult(randomness);
      uint256 targetPoint = abi.decode(bet.data, (uint256));
      // crashPoint is already in cents (e.g., 200 = 2.00x)
      // Check if crash point >= target point for win
      if (targetPoint > 0 && crashPoint >= targetPoint) {
        payout = (bet.amount * targetPoint) / 100; // targetPoint is in cents
      }
      resultData = abi.encode(
        crashPoint,
        payout > 0 ? targetPoint : uint256(0)
      );
    } else if (bet.game == Game.RouletteEvenMoney) {
      uint8 betType = abi.decode(bet.data, (uint8));
      (uint8 winningNumber, bool won) = GameLibrary.rouletteEvenMoneyBet(
        betType,
        randomness
      );
      payout = won ? (bet.amount * 2) : 0;
      resultData = abi.encode(winningNumber, won ? uint256(2) : uint256(0));
    }

    bet.resolved = true;

    if (payout > 0) {
      payable(bet.player).transfer(payout);
    }
    emit BetResolved(requestId, bet.player, payout, resultData);
  }

  // allow contract to receive ETH (e.g. to fund payouts)
  receive() external payable {}
}
