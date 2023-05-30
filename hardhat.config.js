require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

module.exports = {
  solidity: "0.8.18",
  settings: {
    optimizer: {
      enabled: true,
      runs: 10,
    },
  },
  networks: {
    mumbai: {
      url: process.env.RPC,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
