require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

module.exports = {
  solidity: "0.8.18",
  mocha: {
    timeout: 1000000000,
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 10,
    },
  },
  networks: {
    mumbai: {
      url: process.env.RPC,
      accounts: [`0x${process.env.PRIV_KEY}`]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
