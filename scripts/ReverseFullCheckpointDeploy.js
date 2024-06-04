const hre = require("hardhat");
const deploy = require("../deployment.config.json");
const parentnet = require("./utils/xdcnet");
const network = require("../network.config.json");
async function main() {
  const parentnetDeploy = deploy["parentnet"];
  const { data0Encoded } = await parentnet.data(
    network.xdcparentnet,
    parentnetDeploy["v2esbn"]
  );

  // We get the contract to deploy
  const checkpointFactory = await hre.ethers.getContractFactory(
    "ReverseFullCheckpoint"
  );

  let full;
  try {
    full = await checkpointFactory.deploy();
  } catch (e) {
    console.error(e, "\n");
    throw Error(
      "deploy to subnet node failure , pls check the parentnet node status"
    );
  }

  await full.deployed();

  const tx = await full.init(
    data0Encoded,
    parentnetDeploy["epoch"],
    parentnetDeploy["v2esbn"]
  );
  await tx.wait();
  console.log("reverse full checkpoint deployed to:", full.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
