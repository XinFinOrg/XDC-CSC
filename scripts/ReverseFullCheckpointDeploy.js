const hre = require("hardhat");
const deploy = require("../deployment.config.json");
const parentnet = require("./utils/parentnet");
async function main() {
  const { data0Encoded, data1Encoded } = await parentnet.data();

  const parentnetDeploy = deploy["parentnet"];
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
    parentnetDeploy["validators"],
    data0Encoded,
    data1Encoded,
    parentnetDeploy["gap"],
    parentnetDeploy["epoch"],
    parentnetDeploy["initV2Epoch"]
  );
  await tx.wait();
  console.log("full checkpoint deployed to:", full.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
