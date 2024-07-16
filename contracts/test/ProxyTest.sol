// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

contract ProxyTest {
    struct HeaderInfo {
        bytes32 parentHash;
        int256 number;
        uint64 roundNum;
        int256 mainnetNum;
        bool finalized;
    }

    function getHeaderByNumber(
        uint256
    ) external pure returns (HeaderInfo memory) {
        return
            HeaderInfo({
                parentHash: 0x0000000000000000000000000000000000000000000000000000000000000666,
                number: 666,
                roundNum: 666,
                mainnetNum: 666,
                finalized: true
            });
    }
}
