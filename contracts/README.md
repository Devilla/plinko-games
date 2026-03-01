# Smart contracts

Solidity contracts for the backend, targeting **Avalanche Fuji testnet** (chain ID 43113).

## Prerequisites

- [Foundry](https://getfoundry.sh): `curl -L https://foundry.paradigm.xyz | bash` then `foundryup`

## Setup

```bash
cd contracts
forge install foundry-rs/forge-std
```

Do not pass `--no-commit`; that flag was removed in newer Foundry. This creates `lib/forge-std` so imports resolve.

Optional: copy `.env.example` to `.env` and set `AVALANCHE_FUJI_RPC_URL` for forking or deployment.

## Build

```bash
forge build
```

## Test

```bash
forge test
```

Tests run against a local in-memory chain (no Fuji RPC required). To run tests forked from Fuji:

```bash
forge test --fork-url https://api.avax-test.network/ext/bc/C/rpc
```

## Sample contract

`src/Counter.sol` is a minimal counter used to verify the setup. It exposes `increment()`, `decrement()`, `reset()`, and a public `count()`.
