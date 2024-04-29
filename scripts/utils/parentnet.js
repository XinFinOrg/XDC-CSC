const fetch = require("node-fetch").default;
const network = require("../../network.config.json");

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

async function data() {
  const block0 = {
    jsonrpc: "2.0",
    method: "XDPoS_getV2BlockByNumber",
    params: ["0x0"],
    id: 1,
  };
  const block1 = {
    jsonrpc: "2.0",
    method: "XDPoS_getV2BlockByNumber",
    params: ["0x1"],
    id: 1,
  };
  let data0;
  let data1;
  try {
    console.error("connecting to parentnet at url:", network["xdcparentnet"]);
    const block0res = await fetch(network["xdcparentnet"], {
      method: "POST",
      body: JSON.stringify(block0),
      headers: { "Content-Type": "application/json" },
    });
    const block1res = await fetch(network["xdcparentnet"], {
      method: "POST",
      body: JSON.stringify(block1),
      headers: { "Content-Type": "application/json" },
    });
    data0 = await block0res.json();
    data1 = await block1res.json();
  } catch (e) {
    console.error(e, "\n");
    throw Error(
      "Fetch remote subnet node data error , pls check the subnet node status"
    );
  }

  if (!data0["result"]["Committed"] || !data1["result"]["Committed"]) {
    console.error(
      "remote subnet node block data 0 or block 1 is not committed"
    );
    return;
  }
  const data0Encoded = "0x" + base64ToHex(data0["result"]["EncodedRLP"]);
  const data1Encoded = "0x" + base64ToHex(data1["result"]["EncodedRLP"]);

  return { data0Encoded, data1Encoded };
}

module.exports = { data };
