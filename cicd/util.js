process.chdir(__dirname);
const { execSync } = require("child_process");
const fs = require("node:fs");
const dotenv = require("dotenv")
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
          return 1
        }
        console.log("response.data.error", response.data.error)
        throw Error("error in subnet gapblock response")
      }
      epochBlockNum = response.data.result.EpochBlockNumber;
      gapBlockNum = epochBlockNum-450+1
      if (gapBlockNum < 1){
        gapBlockNum = 1
      }
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


function loadContractENV(){
  dotenv.config({ path: "mount/contract_deploy.env" });
}
function loadCommonENV(){
  dotenv.config({ path: "mount/common.env" });
}

function replaceENV(filepath, replaceENV, replaceValue){
  //check files mounted
  if (!fs.existsSync(filepath)) {
    throw Error(`could not modify ${filepath}, file not mounted`)
  } 
  const envFileContent = fs.readFileSync(filepath, 'utf8');
  const regex = new RegExp(`^${replaceENV}=.*`, 'gm');
  let matches = envFileContent.match(regex);
  matches = (matches === null) ? [] : matches
  
  if (matches.length > 1){
    console.log('Warning: found more than one instance of', replaceENV, 'in', filepath)
    console.log(matches)
  }
  let matchesCount = 0
  const updatedContent = envFileContent.replace(regex, (match) => {
    let replaceString=
`# Commented old value by deployer
# ${matches[matchesCount]}`

    if (matchesCount == matches.length-1) { 
      replaceString+=`\n${replaceENV}=${replaceValue}`
    }
    matchesCount++
    console.log(`Updated ${filepath} file: \n${replaceString}`);
    return replaceString
    });

  fs.writeFileSync(filepath, updatedContent);
  return (updatedContent !== envFileContent)
}

function addENV(filepath, envName, envValue){
  //check files mounted
  if (!fs.existsSync(filepath)) {
    throw Error(`could not modify ${filepath}, file not mounted`)
  } 
  const envFileContent = fs.readFileSync(filepath, 'utf8');
  const appendString = `${envName}=${envValue}`
  const updatedContent = envFileContent+'\n'+appendString
  
  fs.writeFileSync(filepath, updatedContent);
}

function replaceOrAddENV(filepath, envKey, envValue){
  replaced = replaceENV(filepath, envKey, envValue)
  !replaced && addENV(filepath, envKey, envValue)
}

async function transferTokens(url, fromPK, toPK, amount) {
  console.log(url)
  const provider = new ethers.providers.JsonRpcProvider(url);
  const fromWallet = new ethers.Wallet(fromPK, provider);
  const toWallet = new ethers.Wallet(toPK, provider);
  let tx = {
    to: toWallet.address,
    value: ethers.utils.parseEther(amount.toString()),
  };

  try{
    await provider.detectNetwork();
  } catch (error){
    throw Error("Cannot connect to RPC")
  }

  let sendPromise = fromWallet.sendTransaction(tx);
  txHash = await sendPromise.then((tx) => {
    return tx.hash;
  });
  console.log("TX submitted, confirming TX execution, txhash:", txHash);

  let receipt;
  let count = 0;
  while (!receipt) {
    count++;
    // console.log("tx receipt check loop", count);
    if (count > 60) {
      throw Error("Timeout: transaction did not execute after 60 seconds");
    }
    await sleep(1000);
    let receipt = await provider.getTransactionReceipt(txHash);
    if (receipt && receipt.status == 1) {
      console.log("Successfully transferred", amount, "subnet token");
      let fromBalance = await provider.getBalance(fromWallet.address);
      fromBalance = ethers.utils.formatEther(fromBalance);
      let toBalance = await provider.getBalance(toWallet.address);
      toBalance = ethers.utils.formatEther(toBalance);
      console.log("Current balance");
      console.log(`${fromWallet.address}: ${fromBalance}`);
      console.log(`${toWallet.address}: ${toBalance}`);
      return {
        fromBalance: fromBalance,
        toBalance: toBalance,
        txHash: txHash
      }
    }
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = {
  callExec,
  writeEnv,
  writeNetworkJson,
  getGapSubnet,
  getEpochParentnet,
  loadContractENV,
  loadCommonENV,
  replaceENV,
  addENV,
  replaceOrAddENV,
  transferTokens,
};
