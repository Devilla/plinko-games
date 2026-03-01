// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ProvablyFair Seed Manager
/// @notice Stores hashed server seeds per address and allows revealing them later.
///         This is a minimal helper contract to move server-seed handling on-chain.
import 'chainlink/v0.8/VRFConsumerBase.sol';

contract ProvablyFair is VRFConsumerBase {
  // hashed server seed that has been committed or generated via VRF
  mapping(address => bytes32) public hashedServerSeed;
  // revealed server seed (only set once a hash has been committed)
  mapping(address => bytes32) public revealedServerSeed;
  // track pending VRF requests
  // mapping from VRF request IDs to the user who initiated the request
  // marked internal so derived mocks in tests can manipulate it
  mapping(bytes32 => address) internal requestIdToUser;

  bytes32 internal keyHash;
  uint256 internal fee;

  event ServerSeedCommitted(address indexed user, bytes32 hashed);
  event ServerSeedRevealed(address indexed user, bytes32 seed);
  event ServerSeedRotated(address indexed user, bytes32 newHashed);
  event ServerSeedRequested(address indexed user, bytes32 requestId);
  event VRFFulfilled(address indexed user, bytes32 seed);

  /// @notice manually commit a server seed hash (legacy path or testing)
  /// @param hashed the hash of the seed
  function commitServerSeed(bytes32 hashed) external {
    require(hashed != bytes32(0), 'hashed cannot be zero');
    require(hashedServerSeed[msg.sender] == bytes32(0), 'already committed');
    hashedServerSeed[msg.sender] = hashed;
    emit ServerSeedCommitted(msg.sender, hashed);
  }

  /// @param vrfCoordinator address of the Chainlink VRF coordinator
  /// @param linkToken address of the LINK token contract
  /// @param _keyHash keyHash used by the VRF job
  /// @param _fee LINK fee required per request
  constructor(
    address vrfCoordinator,
    address linkToken,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(vrfCoordinator, linkToken) {
    keyHash = _keyHash;
    fee = _fee;
  }

  /// @notice Request a new server seed from Chainlink VRF. The resulting
  ///         randomness is stored as the server seed when fulfilled.
  function requestServerSeed() external virtual returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK');
    requestId = requestRandomness(keyHash, fee);
    requestIdToUser[requestId] = msg.sender;
    emit ServerSeedRequested(msg.sender, requestId);
  }

  /// @notice helper intended for tests only.  Allows a derived contract to
  ///         artificially fulfill a request without going through the LINK
  ///         token machinery.
  function _manualFulfill(bytes32 requestId, uint256 randomness) internal {
    fulfillRandomness(requestId, randomness);
  }

  /// @notice Internal callback used by VRFCoordinator.  Converts the random
  ///         value to a seed and commits its hash for the requesting user.
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  ) internal override {
    address user = requestIdToUser[requestId];
    // if we don't have a user mapped something went wrong
    if (user == address(0)) {
      return;
    }
    bytes32 seed = bytes32(randomness);
    bytes32 hashed = keccak256(abi.encodePacked(seed));
    hashedServerSeed[user] = hashed;
    emit VRFFulfilled(user, seed);
    emit ServerSeedCommitted(user, hashed);
    // clear mapping to save gas
    delete requestIdToUser[requestId];
  }

  /// @notice Reveal the previously committed server seed.  The provided seed must
  ///         hash to the value stored by the caller.
  /// @param seed the original server seed
  function revealServerSeed(bytes32 seed) external {
    bytes32 committed = hashedServerSeed[msg.sender];
    require(committed != bytes32(0), 'no commit');
    require(revealedServerSeed[msg.sender] == bytes32(0), 'already revealed');
    require(keccak256(abi.encodePacked(seed)) == committed, 'hash mismatch');

    revealedServerSeed[msg.sender] = seed;
    emit ServerSeedRevealed(msg.sender, seed);
  }

  /// @notice Rotate the server seed hash after the previous one has been revealed.
  ///         This allows users to set up a new hashed seed for the next round.
  /// @param newHashed the hash of the new server seed
  function rotateServerSeed(bytes32 newHashed) external {
    require(newHashed != bytes32(0), 'new hash zero');
    require(
      revealedServerSeed[msg.sender] != bytes32(0),
      'previous not revealed'
    );

    hashedServerSeed[msg.sender] = newHashed;
    revealedServerSeed[msg.sender] = bytes32(0);
    emit ServerSeedRotated(msg.sender, newHashed);
  }
}
