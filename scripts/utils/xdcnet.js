const fetch = require("node-fetch").default;

function base64ToHex(base64String) {
  // Step 1: Decode base64 string to binary data
  var binaryString = atob(base64String);

  // Step 2: Convert binary data to hex
  var hexString = "";
  for (var i = 0; i < binaryString.length; i++) {
    var hex = binaryString.charCodeAt(i).toString(16);
    hexString += hex.length === 2 ? hex : "0" + hex;
  }

  return hexString;
}

async function validators(url, number) {
  const block0 = {
    jsonrpc: "2.0",
    method: "XDPoS_getMasternodesByNumber",
    params: ["0x" + Number(number).toString(16)],
    id: 1,
  };

  const data0 = await send(url, block0);

  if (!data0["result"]["Masternodes"]) {
    console.error("remote node block " + number + " no validators");
    return;
  }

  return data0["result"]["Masternodes"];
}

async function data(url, number) {
  const block0 = {
    jsonrpc: "2.0",
    method: "XDPoS_getV2BlockByNumber",
    params: ["0x" + Number(number).toString(16)],
    id: 1,
  };

  const data0 = await send(url, block0);

  if (!data0["result"]["Committed"]) {
    console.error("remote node block " + number + " is not committed");
    return;
  }
  const data0Encoded = "0x" + base64ToHex(data0["result"]["EncodedRLP"]);

  return { data0Encoded };
}

async function send(url, body) {
  let data;
  try {
    console.error("connecting to network at url:", url);
    const block0res = await fetch(url, {
      method: "POST",
      body: JSON.stringify(body),
      headers: { "Content-Type": "application/json" },
    });

    data = await block0res.json();
  } catch (e) {
    console.error(e, "\n");
    throw Error("Fetch remote node data error , pls check the node status");
  }
  return data;
}

module.exports = { data, validators };
