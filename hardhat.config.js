/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
// require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");
require("solidity-coverage");
require("dotenv").config();
const { utils } = require("ethers");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // forking: {
      //   url: "https://bsc-dataseed.binance.org/",
      //   blockNumber: 32767112,
      // },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 200000,
  },
};
