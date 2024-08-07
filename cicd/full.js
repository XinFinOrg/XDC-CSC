process.chdir(__dirname);
const { execSync } = require("child_process");
const fs = require("node:fs");
const env = require("dotenv").config({ path: "mount/.env" });
const config = {
  relativePath: "../",
};
const u = require("./util.js");

main();

async function main() {
  console.log("start deploying full CSC");
  initDeployFull();
  await configureFiles();
  deployFull();
  exportFull();
}

function initDeployFull() {
  const reqENV = ["PARENTNET_URL", "SUBNET_URL", "PARENTNET_PK"];
  const isEnabled = reqENV.every((envVar) => envVar in process.env);
  if (!isEnabled) {
    throw Error(
      "incomplete ENVs, require PARENTNET_URL, SUBNET_URL, PARENTNET_PK"
    );
  }
  parentnetPK = process.env.PARENTNET_PK.startsWith("0x")
    ? process.env.PARENTNET_PK
    : `0x${process.env.PARENTNET_PK}`;
  config["parentnetPK"] = parentnetPK;
  config["parentnetURL"] = process.env.PARENTNET_URL;
  config["subnetURL"] = process.env.SUBNET_URL;
}

async function configureFiles() {
  u.writeEnv(config.parentnetPK, config.relativePath);
  u.writeNetworkJson(config);

  if (fs.existsSync("./mount/deployment.config.json")) {
    const dpjs = JSON.parse(
      fs.readFileSync("./mount/deployment.config.json", "utf8")
    );
    console.log(
      "copying mounted deployment.config.json, start subnet block:",
      dpjs.subnet.gsbn
    );

    fs.copyFile(
      "mount/deployment.config.json",
      `${config.relativePath}/deployment.config.json`,
      (err) => {
        if (err) {
          throw Error("error writing deployment.config.json, " + err);
        }
      }
    );
  } else {
    gap = await u.getGapSubnet(config);
    writeFullDeployJson(gap);
  }
}

function deployFull() {
  console.log("deploying full csc");
  fullDeployOut = u.callExec(
    `
    cd ${config.relativePath}; 
    npx hardhat run scripts/FullCheckpointDeploy.js --network xdcparentnet
    `
  );
  fullCSC = parseFullOut(fullDeployOut);
  config["fullCSC"] = fullCSC;
}

function exportFull() {
  console.log(
    "SUCCESS deploy full csc, please include the following line in your common.env"
  );
  console.log(`CHECKPOINT_CONTRACT=${config.fullCSC}\n`);
  fs.appendFileSync(
    "mount/csc.env",
    `\nFULL_CSC=${config.fullCSC}\n`,
    "utf-8",
    (err) => {
      if (err) {
        throw Error("error writing mount/csc.env, " + err);
      }
    }
  );
}

function parseFullOut(outString) {
  strArr = outString.split("\n");
  lastLine = strArr[strArr.length - 1];
  if (lastLine == "") {
    strArr.pop();
    lastLine = strArr[strArr.length - 1];
  }
  if (lastLine.includes("0x")) {
    idx = lastLine.indexOf("0x");
    address = lastLine.slice(idx, idx + 42);
    return address;
  } else {
    throw Error("invalid output string: " + outString);
  }
}

function writeFullDeployJson(gsbn) {
  console.log("writing deployment configuration, start subnet block:", gsbn);
  deployJson = {
    subnet: {
      gap: 450,
      epoch: 900,
      gsbn: gsbn,
    },
  };
  fs.writeFileSync(
    `${config.relativePath}/deployment.config.json`,
    JSON.stringify(deployJson, null, 2),
    "utf-8",
    (err) => {
      if (err) {
        throw Error("error writing deployment.config.json, " + err);
      }
    }
  );
  // "subnet": {
  //   "gap": 450,
  //   "epoch": 900,
  //   "gsbn": 1500751
  // },
}
