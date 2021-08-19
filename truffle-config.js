const HDWalletProvider = require('@truffle/hdwallet-provider'); 

const provider = new HDWalletProvider(
  ['YOUR PRIVATE KEY HERE'],
  'YOUR INFURA API KEY HERE'
);

module.exports = {
   networks: {
    mainnet: {
      network_id: 1,
      gas: 3000000,
      gasPrice: 10000000000,
      provider: () => provider
    },
    kovan: {
      network_id: 42,
      gas: 12500000,
      gasPrice: 10000000000,
      provider: () => provider
    },
    development: {
       host: "127.0.0.1",
       port: 8545,
       network_id: "*",
       provider: () => provider
    },
    binanceTestnet: {
      network_id: "97",
      gas: 1000000,
      provider: () => provider
    },
  },
  compilers: {
    solc: {
      version: "0.6.12"
    }
  }
};
