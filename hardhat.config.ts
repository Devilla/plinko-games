import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox-mocha-ethers';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      remappings: [
        'chainlink/=./contracts/lib/chainlink/src/',
        'forge-std/=./contracts/lib/forge-std/src/',
      ],
    },
  },
  paths: {
    sources: './contracts/src',
    tests: './contracts/test',
    cache: './contracts/cache-hardhat',
    artifacts: './contracts/artifacts-hardhat',
  },
};

export default config;
