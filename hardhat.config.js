/** @type import('hardhat/config').HardhatUserConfig */
require('@openzeppelin/hardhat-upgrades')
require("hardhat-gas-reporter");
require("solidity-coverage")
require('solidity-docgen')
require("hardhat-contract-sizer");
require("@nomicfoundation/hardhat-chai-matchers")
module.exports = {
  solidity: {
    version: '0.8.36',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: 'prague'
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === 'true'
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    //only: [':ERC20$'],
  }
}
