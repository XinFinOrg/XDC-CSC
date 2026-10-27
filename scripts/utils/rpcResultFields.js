// XDPoS RPC responses differ by client: XDPoSChain returns PascalCase keys ("EncodedRLP") and JSON
// numbers, while Nethermind returns camelCase keys ("encodedRLP") and hex strings ("0x47").
// These helpers read a field from either shape, as the relayer does.

function getField(result, key) {
  if (result === null || typeof result !== "object") {
    return undefined;
  }
  if (key in result) {
    return result[key];
  }
  const lowerKey = key.toLowerCase();
  const match = Object.keys(result).find((k) => k.toLowerCase() === lowerKey);
  return match === undefined ? undefined : result[match];
}

// Number() parses both decimal and "0x" hex strings; a missing value stays undefined so callers can
// tell it apart from zero.
function getNumberField(result, key) {
  const value = getField(result, key);
  return value === undefined || value === null ? undefined : Number(value);
}

module.exports = { getField, getNumberField };
