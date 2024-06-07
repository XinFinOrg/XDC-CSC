const hre = require("hardhat");
const deploy = require("../deployment.config.json");
const subnet = require("./utils/xdcnet");
const network = require("../network.config.json");

async function main() {
  const { data0Encoded } = await subnet.data(network.xdcsubnet, 1);
  const validators = await subnet.validators(network.xdcsubnet, 1);
  const subnetDeploy = deploy["subnet"];
  // We get the contract to deploy
  const checkpointFactory = await hre.ethers.getContractFactory(
    "LiteCheckpoint"
  );

  let lite;
  try {
    lite = await checkpointFactory.deploy();
  } catch (e) {
    console.error(e, "\n");
    throw Error(
      "deploy to parentnet node failure , pls check the parentnet node status"
    );
  }

  await lite.deployed();
  const tx = await lite.init(
    validators,
    data0Encoded,
    subnetDeploy["gap"],
    subnetDeploy["epoch"]
  );
  await tx.wait();
  console.log("lite checkpoint deployed to:", lite.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
