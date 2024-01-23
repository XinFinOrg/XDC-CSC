const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const proxyGatewayFactory = await hre.ethers.getContractFactory(
    "ProxyGateway"
  );

  let proxyGateway;
  try {
    console.log("deploying proxygateway to parentnet url: ", hre.network.config.url)
    proxyGateway = await proxyGatewayFactory.deploy();
  } catch (e) {
    console.error(e, "\n")
    throw Error(
      "deploy to parentnet node failure , pls check the parentnet node status"
    );
  }

  await proxyGateway.deployed();

  console.log("proxyGateway deployed to:", proxyGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
