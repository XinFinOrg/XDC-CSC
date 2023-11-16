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
      url: "https://devnetstats.apothem.network/devnet",
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
    xdctestnet: {
      url: "https://erpc.apothem.network/",
      accounts: [
        process.env.PRIVATE_KEY ||
          "1234567890123456789012345678901234567890123456789012345678901234",
      ],
    },
  },
};
