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
  console.log("start deploying reverse CSC");
  initDeployReverse();
  await configureFiles();
  deployReverse();
  exportReverse();
}

function initDeployReverse() {
  const reqENV = ["PARENTNET_URL", "SUBNET_URL", "SUBNET_PK"];
  const isEnabled = reqENV.every((envVar) => envVar in process.env);
  if (!isEnabled) {
    throw Error(
      "incomplete ENVs, require PARENTNET_URL, SUBNET_URL, SUBNET_PK"
    );
  }
  subnetPK = process.env.SUBNET_PK.startsWith("0x")
    ? process.env.SUBNET_PK
    : `0x${process.env.SUBNET_PK}`;
  config["parentnetURL"] = process.env.PARENTNET_URL;
  config["subnetURL"] = process.env.SUBNET_URL;
  config["subnetPK"] = subnetPK;
}

async function configureFiles() {
  u.writeEnv(config.subnetPK, config.relativePath);
  u.writeNetworkJson(config);

  if (fs.existsSync("./mount/deployment.config.json")) {
    const dpjs = JSON.parse(
      fs.readFileSync("./mount/deployment.config.json", "utf8")
    );
    console.log(
      "copying mounted deployment.config.json, start parentnet block:",
      dpjs.parentnet.v2esbn
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
    epoch = await u.getEpochParentnet(config);
    writeReverseDeployJson(epoch);
  }
}

function deployReverse() {
  console.log("deploying reverse csc");
  reverseDeployOut = u.callExec(
    `
    cd ${config.relativePath}; 
    npx hardhat run scripts/ReverseFullCheckpointDeploy.js --network xdcsubnet
    `
  );
  reverseCSC = parseReverseOut(reverseDeployOut);
  config["reverseCSC"] = reverseCSC;
}

function exportReverse() {
  console.log(
    "SUCCESS deploy reverse csc, please include the following line in your common.env"
  );
  console.log(`REVERSE_CHECKPOINT_CONTRACT=${config.reverseCSC}\n`);
  fs.appendFileSync(
    "mount/csc.env",
    `\nREVERSE_CSC=${config.reverseCSC}\n`,
    "utf-8",
    (err) => {
      if (err) {
        throw Error("error writing mount/csc.env, " + err);
      }
    }
  );
}

function parseReverseOut(outString) {
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

function writeReverseDeployJson(v2esbn) {
  console.log(
    "writing deployment configuration, start parentnet block:", v2esbn
  );
  deployJson = {
    parentnet:{
      epoch: 900,
      v2esbn: v2esbn,
    }
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
