const { expect } = require("chai");
const { getField, getNumberField } = require("../scripts/utils/rpcResultFields");

describe("XDPoS RPC result fields", () => {
  const xdposchain = {
    Committed: true,
    EncodedRLP: "+QMY",
    Masternodes: ["0x25c65b4b379ac37cf78357c4915f73677022eaff"],
    EpochBlockNumber: 84999559,
  };
  const nethermind = {
    committed: true,
    encodedRLP: "+QMY",
    masternodes: ["0x25c65b4b379ac37cf78357c4915f73677022eaff"],
    epochBlockNumber: "0x510fd87",
  };

  [
    ["XDPoSChain", xdposchain],
    ["Nethermind", nethermind],
  ].forEach(([client, result]) => {
    it(`reads ${client} results`, () => {
      expect(getField(result, "Committed")).to.equal(true);
      expect(getField(result, "EncodedRLP")).to.equal("+QMY");
      expect(getField(result, "Masternodes")).to.deep.equal([
        "0x25c65b4b379ac37cf78357c4915f73677022eaff",
      ]);
      expect(getNumberField(result, "EpochBlockNumber")).to.equal(84999559);
    });
  });

  it("leaves missing fields and failed calls undefined", () => {
    expect(getField(xdposchain, "Round")).to.be.undefined;
    expect(getNumberField(nethermind, "Round")).to.be.undefined;
    expect(getField(undefined, "Committed")).to.be.undefined;
  });
});
