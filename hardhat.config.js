const { VoidSigner } = require("ethers");

require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("dotenv").config();

try {
  var network = require("./deployment.config.json");
 }
 catch (e) {
  var network = {
      "xdcparentnet": "https://devnetstats.apothem.network/devnet",
      "xdcdevnet": "https://devnetstats.apothem.network/devnet",
      "xdctestnet": "https://erpc.apothem.network/",
      "xdcsubnet": "https://devnetstats.apothem.network/subnet"
    }
 }

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true
    },
  },
  networks: {
    xdcparentnet: {
      url: network["xdcparentnet"],
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
    xdcsubnet: {
      url: network["xdcsubnet"],
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
    xdcdevnet: {
      url: network["xdcdevnet"],
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
    xdctestnet: {
      url: network["xdctestnet"],
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
  },
};
