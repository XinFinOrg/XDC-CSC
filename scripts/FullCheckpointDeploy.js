const hre = require("hardhat");
const deploy = require("../deployment.config.json");
const subnet = require("./utils/subnet");
async function main() {
  const subnetDeploy = deploy["subnet"];

  const { data0Encoded } = await subnet.data(subnetDeploy.gsbn);

  // We get the contract to deploy
  const checkpointFactory = await hre.ethers.getContractFactory(
    "FullCheckpoint"
  );

  let full;
  try {
    full = await checkpointFactory.deploy();
  } catch (e) {
    console.error(e, "\n");
    throw Error(
      "deploy to parentnet node failure , pls check the parentnet node status"
    );
  }

  await full.deployed();

  const tx = await full.init(
    subnetDeploy["validators"],
    data0Encoded,
    subnetDeploy["gap"],
    subnetDeploy["epoch"],
    subnetDeploy.gsbn
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
