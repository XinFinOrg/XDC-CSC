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

async function data(url, number) {
  const block0 = {
    jsonrpc: "2.0",
    method: "XDPoS_getV2BlockByNumber",
    params: ["0x" + Number(number).toString(16)],
    id: 1,
  };

  let data0;
  try {
    console.error("connecting to network at url:", url);
    const block0res = await fetch(url, {
      method: "POST",
      body: JSON.stringify(block0),
      headers: { "Content-Type": "application/json" },
    });

    data0 = await block0res.json();
  } catch (e) {
    console.error(e, "\n");
    throw Error("Fetch remote node data error , pls check the node status");
  }

  if (!data0["result"]["Committed"]) {
    console.error("remote node block " + number + " is not committed");
    return;
  }
  const data0Encoded = "0x" + base64ToHex(data0["result"]["EncodedRLP"]);

  return { data0Encoded };
}

module.exports = { data };
