const { ethers } = require("hardhat");
const secp256k1 = require("secp256k1");
const RLP = require("rlp");
const util = require("@ethereumjs/util");
const hex2Arr = (hexString) => {
  if (hexString.length % 2 !== 0) {
    throw "Must have an even number of hex digits to convert to bytes";
  }
  var numBytes = hexString.length / 2;
  var byteArray = new Uint8Array(numBytes);
  for (var i = 0; i < numBytes; i++) {
    byteArray[i] = parseInt(hexString.substr(i * 2, 2), 16);
  }
  return byteArray;
};
function blockToHash(blockEncoded) {
  return ethers.utils
    .keccak256(Buffer.from(hex2Arr(blockEncoded.slice(2))))
    .toString("hex");
}
const hash = (block) => {
  return ethers.utils.keccak256(block);
};

const encoded = (block) => {
  return "0x" + block.toString("hex");
};
const getGenesis = (validators) => {
  const voteForSignHash = ethers.utils.keccak256(
    Buffer.from(
      RLP.encode([
        [
          "0x0000000000000000000000000000000000000000000000000000000000000000",
          0,
          0,
        ],
        0,
      ])
    )
  );
  const version = new Uint8Array([2]);
  const sigs = getSigs(voteForSignHash, validators, 3);
  return Buffer.from(
    RLP.encode([
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      new Uint8Array(256),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      new Uint8Array([
        ...version,
        ...RLP.encode([
          0,
          [
            [
              "0x0000000000000000000000000000000000000000000000000000000000000000",
              0,
              0,
            ],
            sigs,
            0,
          ],
        ]),
      ]),
      util.zeros(32),
      new Uint8Array(8),
      new Uint8Array(8),
      [],
      [],
      [],
    ])
  );
};

const getSigs = (voteForSignHash, validators, sigNum) => {
  const rawSigs = [];
  for (let i = 0; i < sigNum; i++) {
    rawSigs.push(
      secp256k1.ecdsaSign(
        hex2Arr(voteForSignHash.substring(2)),
        hex2Arr(validators[i].privateKey.substring(2))
      )
    );
  }

  const sigs = rawSigs.map((x) => {
    var res = new Uint8Array(65);
    res.set(x.signature, 0);
    res.set([x.recid], 64);
    return "0x" + Buffer.from(res).toString("hex");
  });

  return sigs;
};

const composeAndSignBlockSubnet = (
  number,
  round_num,
  prn,
  parent_hash,
  validators,
  threshold,
  current,
  next,
  penalties = []
) => {
  const version = new Uint8Array([2]);
  const voteForSignHash = ethers.utils.keccak256(
    Buffer.from(RLP.encode([[parent_hash, prn, number - 1], 0]))
  );

  const sigs = getSigs(voteForSignHash, validators, threshold);

  var block = {
    parentHash: parent_hash,
    uncleHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    coinbase:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    root: "0x0000000000000000000000000000000000000000000000000000000000000000",
    txHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    receiptAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    bloom: new Uint8Array(256),
    difficulty: 0,
    number: number,
    gasLimit: 0,
    gasUsed: 0,
    time: 0,
    extra: new Uint8Array([
      ...version,
      ...RLP.encode([round_num, [[parent_hash, prn, number - 1], sigs, 0]]),
    ]),
    mixHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    nonce: new Uint8Array(8),
    validator: new Uint8Array(8),
    validators: current,
    nextValidators: next,
    penalties: penalties,
  };

  var blockBuffer = Buffer.from(
    RLP.encode([
      util.toBytes(parent_hash),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      new Uint8Array(256),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(number),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      new Uint8Array([
        ...version,
        ...RLP.encode([round_num, [[parent_hash, prn, number - 1], sigs, 0]]),
      ]),
      util.zeros(32),
      new Uint8Array(8),
      new Uint8Array(8),
      current,
      next,
      penalties,
    ])
  );

  return [block, encoded(blockBuffer), hash(blockBuffer)];
};

function hexStringToUint8Array(hexString) {
  if (hexString.substring(0, 2) === "0x") {
    hexString = hexString.substring(2);
  }

  const uint8Array = new Uint8Array(hexString.length / 2);
  for (let i = 0; i < hexString.length; i += 2) {
    uint8Array[i / 2] = parseInt(hexString.substring(i, i + 2), 16);
  }
  return uint8Array;
}

function arrayToUint8Array(array) {
  const uint8Arrays = array.map(hexStringToUint8Array);
  const mergedUint8Array = uint8Arrays.reduce((acc, curr) => {
    const merged = new Uint8Array(acc.length + curr.length);
    merged.set(acc, 0);
    merged.set(curr, acc.length);
    return merged;
  }, new Uint8Array(0));
  return mergedUint8Array;
}

const composeAndSignBlockMainnet = (
  number,
  round_num,
  prn,
  parent_hash,
  validators,
  threshold,
  next = [],
  penalties = []
) => {
  const version = new Uint8Array([2]);
  const voteForSignHash = ethers.utils.keccak256(
    Buffer.from(RLP.encode([[parent_hash, prn, number - 1], 0]))
  );

  const sigs = getSigs(voteForSignHash, validators, threshold);

  var block = {
    parentHash: parent_hash,
    uncleHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    coinbase:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    root: "0x0000000000000000000000000000000000000000000000000000000000000000",
    txHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    receiptAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    bloom: new Uint8Array(256),
    difficulty: 0,
    number: number,
    gasLimit: 0,
    gasUsed: 0,
    time: 0,
    extra: new Uint8Array([
      ...version,
      ...RLP.encode([round_num, [[parent_hash, prn, number - 1], sigs, 0]]),
    ]),
    mixHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    nonce: new Uint8Array(8),
    validators: arrayToUint8Array(next),
    validator: new Uint8Array(8),
    penalties: arrayToUint8Array(penalties),
  };

  var blockBuffer = Buffer.from(
    RLP.encode([
      util.toBytes(parent_hash),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      util.zeros(32),
      new Uint8Array(256),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(number),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      util.bigIntToUnpaddedBytes(0),
      new Uint8Array([
        ...version,
        ...RLP.encode([round_num, [[parent_hash, prn, number - 1], sigs, 0]]),
      ]),
      util.zeros(32),
      new Uint8Array(8),
      arrayToUint8Array(next),
      new Uint8Array(8),
      arrayToUint8Array(penalties),
    ])
  );

  return [block, encoded(blockBuffer), hash(blockBuffer)];
};
function createValidators(num) {
  const validators = [];
  for (let i = 0; i < num; i++) {
    validators.push(ethers.Wallet.createRandom());
  }
  return validators;
}

module.exports = {
  getSigs,
  hex2Arr,
  createValidators,
  getGenesis,
  hash,
  encoded,
  composeAndSignBlockSubnet,
  blockToHash,
  composeAndSignBlockMainnet,
};
