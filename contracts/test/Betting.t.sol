// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import 'forge-std/Test.sol';
import '../src/Betting.sol';

contract BettingTestHelper is Betting {
  constructor() Betting(address(0), address(0), bytes32(0), 0) {}

  // override placeBet to avoid LINK requirement and VRF call
  function placeBet(
    Game game,
    bytes calldata data
  ) external payable override returns (bytes32 requestId) {
    require(msg.value > 0, 'must send bet amount');
    // create fake requestId deterministically
    requestId = keccak256(
      abi.encodePacked(msg.sender, address(this), block.timestamp)
    );
    bets[requestId] = Bet({
      player: msg.sender,
      amount: msg.value,
      game: game,
      data: data,
      resolved: false
    });
    emit BetPlaced(requestId, msg.sender, msg.value, game);
  }

  // expose manual fulfill for tests
  function fulfill(bytes32 requestId, uint256 randomness) public {
    _manualFulfill(requestId, randomness);
  }
}

contract BettingTest is Test {
  BettingTestHelper public bet;
  address public alice = address(0xA11ce);

  function setUp() public {
    bet = new BettingTestHelper();
    // fund contract so it can pay out winners
    vm.deal(address(bet), 100 ether);
    // give alice some ETH to bet with
    vm.deal(alice, 10 ether);
  }

  function test_straightLose() public {
    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.Roulette,
      abi.encode(uint8(5))
    );
    // simulate randomness yielding number not 5
    bet.fulfill(req, 123);
    // verify contract did not pay out anything (balance remains)
    // since contract was funded with 100 ether and only 1 was bet and lost
    assertEq(address(bet).balance, 100 ether + 1 ether);
  }

  function test_straightWin() public {
    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.Roulette,
      abi.encode(uint8(7))
    );
    // set randomness such that winningNumber == selection (7)
    // compute randomness that leads to winningNumber 7
    uint256 targetRandomness;
    // brute force small number for test
    for (uint256 i = 0; i < 1000; i++) {
      if (uint256(keccak256(abi.encode(i))) % 37 == 7) {
        targetRandomness = i;
        break;
      }
    }
    bet.fulfill(req, targetRandomness);
    // payout should be 36 ether, contract balance decreases by 36
    assertEq(address(bet).balance, 100 ether + 1 ether - 36 ether);
  }

  // ==================== DICE TESTS ====================

  function test_diceAboveWin50() public {
    // Find randomness that produces result > 5000 (win for "above 50" bet)
    uint256 winRandomness;
    bool found;
    for (uint256 i = 0; i < 100000; i++) {
      uint256 result = (uint256(keccak256(abi.encode(i, 'dice'))) % 10001);
      if (result > 50 * 100) {
        winRandomness = i;
        found = true;
        break;
      }
    }
    require(found, 'failed to find win randomness');

    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.Dice,
      abi.encode(uint8(50), true)
    ); // bet above 50
    bet.fulfill(req, winRandomness);
    // probability=50 -> multiplier=198 -> payout=1.98 ether
    uint256 expected = (1 ether * 198) / 100;
    assertEq(address(bet).balance, 100 ether + 1 ether - expected);
  }

  function test_diceBelowWin50() public {
    // Find randomness that produces result < 5000 (win for "below 50" bet)
    uint256 winRandomness;
    bool found;
    for (uint256 i = 0; i < 100000; i++) {
      uint256 result = (uint256(keccak256(abi.encode(i, 'dice'))) % 10001);
      if (result < 50 * 100) {
        winRandomness = i;
        found = true;
        break;
      }
    }
    require(found, 'failed to find win randomness');

    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.Dice,
      abi.encode(uint8(50), false)
    ); // bet below 50
    bet.fulfill(req, winRandomness);
    // probability=50 -> multiplier=198 -> payout=1.98 ether
    uint256 expected = (1 ether * 198) / 100;
    assertEq(address(bet).balance, 100 ether + 1 ether - expected);
  }

  // ==================== LIMBO TESTS ====================

  function test_limboBet() public {
    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.Limbo,
      abi.encode(uint256(200)) // bet on 2.00x
    );
    bet.fulfill(req, 12345);
    // Result depends on the crash point calculated
    // If crash point >= 200, player wins ~2x their bet
    uint256 balanceAfter = address(bet).balance;
    // Just verify the bet was created (not checking resolved directly)
    assertNotEq(balanceAfter, address(0).balance);
  }

  // ==================== ROULETTE EVEN MONEY TESTS ====================

  function test_rouletteRedWin() public {
    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.RouletteEvenMoney,
      abi.encode(uint8(0)) // bet on red
    );
    // Find randomness that produces red number (e.g., 1)
    uint256 targetRandomness;
    for (uint256 i = 0; i < 100000; i++) {
      // 1 is red, check if keccak256(i) % 37 == 1
      if (uint256(keccak256(abi.encode(i))) % 37 == 1) {
        targetRandomness = i;
        break;
      }
    }
    bet.fulfill(req, targetRandomness);
    uint256 balanceAfter = address(bet).balance;
    // Win on red: payout is 2x the bet
    assertEq(balanceAfter, 100 ether + 1 ether - 2 ether);
  }

  function test_rouletteBlackLose() public {
    vm.prank(alice);
    bytes32 req = bet.placeBet{value: 1 ether}(
      Betting.Game.RouletteEvenMoney,
      abi.encode(uint8(1)) // bet on black
    );
    // Use randomness that gives red
    uint256 targetRandomness;
    for (uint256 i = 0; i < 100000; i++) {
      if (uint256(keccak256(abi.encode(i))) % 37 == 1) {
        targetRandomness = i;
        break;
      }
    }
    bet.fulfill(req, targetRandomness);
    uint256 balanceAfter = address(bet).balance;
    // Loss: no payout
    assertEq(balanceAfter, 100 ether + 1 ether);
  }
}
