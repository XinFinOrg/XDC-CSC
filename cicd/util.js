process.chdir(__dirname);
const { execSync } = require("child_process");
const fs = require("node:fs");
const env = require("dotenv").config({ path: "mount/.env" });

const { ethers } = require("ethers");
const axios = require("axios");

function writeEnv(key, path) {
  content = "PRIVATE_KEY=" + key;
  fullPath = path + "/" + ".env";
  fs.writeFileSync(fullPath, content, (err) => {
    if (err) {
      throw Error(`error writing ${fullPath}, ` + err);
    }
  });
}

function writeNetworkJson(config) {
  networkJson = {
    xdcsubnet: config.subnetURL,
    xdcparentnet: config.parentnetURL,
    xdcdevnet: "", //dummy
    xdctestnet: "",
  };
  writeJson(networkJson, config.relativePath, "network.config.json");
}

function writeJson(obj, path, filename) {
  fullPath = path + "/" + filename;
  fs.writeFileSync(fullPath, JSON.stringify(obj, null, 2), "utf-8", (err) => {
    if (err) {
      throw Error(`error writing ${fullPath}, ` + err);
    }
  });
}

function callExec(command) {
  try {
    const stdout = execSync(command, { timeout: 200000 });
    // const stdout = execSync(command)
    output = stdout.toString();
    // console.log(`${stdout}`);
    console.log(output);
    return output;
  } catch (error) {
    if (error.code) {
      // Spawning child process failed
      if (error.code == "ETIMEDOUT") {
        throw Error("Timed out (200 seconds)");
      } else {
        throw Error(error);
      }
    } else {
      // Child was spawned but exited with non-zero exit code
      // Error contains any stdout and stderr from the child
      // const { stdout, stderr } = error;
      // console.error({ stdout, stderr });
      throw Error(error);
    }
  }
}

async function getGapSubnet(config) {
  console.log("getting subnet latest gap block")
  const data = {
    jsonrpc: "2.0",
    method: "XDPoS_getMissedRoundsInEpochByBlockNum",
    params: ["latest"],
    id: 1,
  };
  return await axios.post(config.subnetURL, data, {timeout: 10000}).then((response) => {
    // console.log(response)
    if (response.status == 200) {
      if (response.data.error){
        if (response.data.error.code == -32601){
          return 0
        }
        console.log("response.data.error", response.data.error)
        throw Error("error in subnet gapblock response")
      }
      epochBlockNum = response.data.result.EpochBlockNumber;
      gapBlockNum = epochBlockNum-450+1
      return gapBlockNum
    } else {
      console.log("response.status", response.status);
      // console.log("response.data", response.data);
      throw Error("could not get gapblock in subnet");
    }
  });

}

async function getEpochParentnet(config) {
  console.log("getting parentnet latest epoch start block")
  const data = {
    jsonrpc: "2.0",
    method: "XDPoS_getMissedRoundsInEpochByBlockNum",
    params: ["latest"],
    id: 1,
  };
  await axios.post(config.parentnetURL, data, {timeout: 10000}).then((response) => {
    if (response.status == 200) {
      epochBlockNum = response.data.result.EpochBlockNumber;
      console.log("epochBlockNum", epochBlockNum)
    } else {
      console.log("response.status", response.status);
      // console.log("response.data", response.data);
      throw Error("could not get epoch block in parentnet");
    }
  });
  return epochBlockNum
}

module.exports = {
  callExec,
  writeEnv,
  writeNetworkJson,
  getGapSubnet,
  getEpochParentnet,
};
