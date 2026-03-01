// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GameLibrary - Pure game logic functions
/// @notice All game calculations are pure functions, deterministic from randomness
library GameLibrary {
  // ==================== ROULETTE ====================

  /// @notice Roulette bet: user selects a number 0-36
  /// @param selection the selected number (0-36)
  /// @param randomness VRF randomness
  /// @return winningNumber the drawn number
  /// @return payoutMultiplier the payout multiplier (0 if loss, 36 if win)
  function rouletteResult(
    uint8 selection,
    uint256 randomness
  ) internal pure returns (uint8 winningNumber, uint256 payoutMultiplier) {
    winningNumber = uint8(uint256(keccak256(abi.encode(randomness))) % 37);
    payoutMultiplier = (selection == winningNumber) ? 36 : 0;
  }

  // ==================== DICE ====================

  /// @notice Dice roll: player bets on rolling above or below a target
  /// @param target the target value (1-99)
  /// @param isAbove true for "above", false for "below"
  /// @param randomness VRF randomness
  /// @return result the dice roll result (0.00-100.00, stored as uint * 100)
  /// @return payoutMultiplier the win multiplier or 0 if loss
  function diceResult(
    uint8 target,
    bool isAbove,
    uint256 randomness
  ) internal pure returns (uint256 result, uint256 payoutMultiplier) {
    // Use randomness to generate a float between 0 and 100
    // Generate a number 0-10000 and divide by 100 to get 0.00-100.00
    result = (uint256(keccak256(abi.encode(randomness, 'dice'))) % 10001);

    // Calculate payout multiplier
    if (isAbove) {
      // Win if result > target
      if (result > target * 100) {
        payoutMultiplier = _calculateDiceMultiplier(target, true);
      }
    } else {
      // Win if result < target
      if (result < target * 100) {
        payoutMultiplier = _calculateDiceMultiplier(target, false);
      }
    }
  }

  /// @notice Internal function to calculate dice payout multiplier
  /// @dev Uses a simplified formula with fixed 2x multiplier for wins
  function _calculateDiceMultiplier(
    uint8,
    bool
  ) internal pure returns (uint256) {
    // Simplified: just return 2x multiplier (like even money bet)
    // Could be enhanced with target-based calculations
    return 2;
  }

  // ==================== LIMBO ====================

  /// @notice Limbo: player bets on crash point
  /// @param randomness VRF randomness
  /// @return crashPoint the crash multiplier (stored as uint, * 100)
  function limboResult(
    uint256 randomness
  ) internal pure returns (uint256 crashPoint) {
    uint256 HOUSE_EDGE = 99; // 0.99
    uint256 floatPoint = (1e8 / ((randomness % 1e8) + 1)) * HOUSE_EDGE;
    crashPoint = (floatPoint / 100); // Round down to cents
    if (crashPoint < 100) {
      crashPoint = 100; // Minimum 1.00x
    }
  }

  // ==================== ROULETTE VARIANTS ====================

  /// @notice Roulette even money bet (red/black, even/odd, high/low)
  /// @param betType 0=red, 1=black, 2=even, 3=odd, 4=high, 5=low
  /// @param randomness VRF randomness
  /// @return winningNumber the drawn number
  /// @return won true if bet wins
  function rouletteEvenMoneyBet(
    uint8 betType,
    uint256 randomness
  ) internal pure returns (uint8 winningNumber, bool won) {
    // Common roulette colors
    uint8[18] memory redNumbers = [
      1,
      3,
      5,
      7,
      9,
      12,
      14,
      16,
      18,
      19,
      21,
      23,
      25,
      27,
      30,
      32,
      34,
      36
    ];

    winningNumber = uint8(uint256(keccak256(abi.encode(randomness))) % 37);
    if (winningNumber == 0) {
      won = false;
      return (winningNumber, won);
    }

    if (betType == 0) {
      // Red
      won = _isInArray(winningNumber, redNumbers);
    } else if (betType == 1) {
      // Black
      won = !_isInArray(winningNumber, redNumbers);
    } else if (betType == 2) {
      // Even
      won = (winningNumber % 2 == 0);
    } else if (betType == 3) {
      // Odd
      won = (winningNumber % 2 == 1);
    } else if (betType == 4) {
      // High (19-36)
      won = (winningNumber >= 19);
    } else if (betType == 5) {
      // Low (1-18)
      won = (winningNumber <= 18);
    }
  }

  /// @notice Helper to check if value is in array
  function _isInArray(
    uint8 value,
    uint8[18] memory arr
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == value) return true;
    }
    return false;
  }
}
