/**
 * EVM chain configuration for backend (smart contracts, RPC calls).
 */

export interface ChainConfig {
  id: number;
  name: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
  rpcUrls: {
    default: { http: string[] };
    public?: { http: string[] };
  };
  blockExplorers?: {
    default: { name: string; url: string };
  };
  testnet?: boolean;
}

/**
 * Avalanche Fuji testnet configuration.
 * Used by the backend for smart contract deployment and interactions.
 * @see https://docs.avax.network/quickstart/fuji-workflow
 */
export const avalancheFuji: ChainConfig = {
  id: 43113,
  name: 'Avalanche Fuji Testnet',
  nativeCurrency: {
    name: 'Avalanche',
    symbol: 'AVAX',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: [
        process.env.AVALANCHE_FUJI_RPC_URL ??
          'https://api.avax-test.network/ext/bc/C/rpc',
      ],
    },
    public: {
      http: ['https://api.avax-test.network/ext/bc/C/rpc'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Snowtrace',
      url: 'https://testnet.snowtrace.io',
    },
  },
  testnet: true,
};

/** All supported chains for backend (add mainnet or other networks here). */
export const supportedChains = [avalancheFuji] as const;

/** Fuji chain ID for quick checks. */
export const AVALANCHE_FUJI_CHAIN_ID = avalancheFuji.id;
