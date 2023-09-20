// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {HeaderReader} from "./libraries/HeaderReader.sol";

contract FullCheckpoint {
    // Compressed subnet header information stored on chain
    struct Header {
        bytes32 receiptHash;
        bytes32 parentHash;
        uint256 mix; // padding 64 | uint64 number | uint64 roundNum | uint64 mainnetNum
    }

    struct HeaderInfo {
        bytes32 parentHash;
        int256 number;
        uint64 roundNum;
        int256 mainnetNum;
        bool finalized;
    }

    struct Validators {
        address[] set;
        int256 threshold;
    }

    struct BlockLite {
        bytes32 hash;
        int256 number;
    }

    mapping(bytes32 => Header) private headerTree;
    mapping(int256 => bytes32) private committedBlocks;
    mapping(address => bool) private lookup;
    mapping(address => bool) private uniqueAddr;
    mapping(int256 => Validators) private validators;
    Validators private currentValidators;
    bytes32 private latestBlock;
    bytes32 private latestFinalizedBlock;

    string public constant MODE = "full";

    uint64 private epochNum;
    uint64 public INIT_STATUS;
    uint64 public INIT_GAP;
    uint64 public INIT_EPOCH;

    // Event types
    event SubnetBlockAccepted(bytes32 blockHash, int256 number);
    event SubnetBlockFinalized(bytes32 blockHash, int256 number);

    function init(
        address[] memory initialValidatorSet,
        bytes memory genesisHeader,
        bytes memory block1Header,
        uint64 initGap,
        uint64 initEpoch
    ) public {
        require(INIT_STATUS == 0, "Already init");
        require(initialValidatorSet.length > 0, "Validator Empty");

        bytes32 genesisHeaderHash = keccak256(genesisHeader);
        bytes32 block1HeaderHash = keccak256(block1Header);
        (bytes32 ph, int256 n, bytes32 receiptHash) = HeaderReader
            .getBlock0Params(genesisHeader);

        HeaderReader.ValidationParams memory block1 = HeaderReader
            .getValidationParams(block1Header);
        require(n == 0 && block1.number == 1, "Invalid Init Block");
        headerTree[genesisHeaderHash] = Header({
            receiptHash: receiptHash,
            parentHash: ph,
            mix: (uint256(n) << 128) | uint256(block.number)
        });
        headerTree[block1HeaderHash] = Header({
            receiptHash: block1.receiptHash,
            parentHash: block1.parentHash,
            mix: (uint256(block1.number) << 128) |
                (uint256(block1.roundNumber) << 64) |
                uint256(block.number)
        });
        validators[1] = Validators({
            set: initialValidatorSet,
            threshold: int256((initialValidatorSet.length * 2 * 100) / 3)
        });
        currentValidators = validators[1];
        setLookup(initialValidatorSet);
        latestBlock = block1HeaderHash;
        latestFinalizedBlock = block1HeaderHash;
        committedBlocks[0] = genesisHeaderHash;
        committedBlocks[1] = block1HeaderHash;
        INIT_GAP = initGap;
        INIT_EPOCH = initEpoch;
        INIT_STATUS = 1;
    }

    /*
     * @description core function in the contract, it can be summarized into three steps:
     * 1. Verify subnet header meta information
     * 2. Verify subnet header certificates
     * 3. (Conditional) Update Committed Status for ancestor blocks
     * @param list of rlp-encoded block headers.
     */
    function receiveHeader(bytes[] calldata headers) public {
        for (uint256 x = 0; x < headers.length; x++) {
            HeaderReader.ValidationParams memory validationParams = HeaderReader
                .getValidationParams(headers[x]);

            (address[] memory current, address[] memory next) = HeaderReader
                .getEpoch(headers[x]);

            // Verify subnet header meta information
            require(validationParams.number > 0, "Repeated Genesis");
            require(
                validationParams.number >
                    int256(
                        uint256(
                            uint64(headerTree[latestFinalizedBlock].mix >> 128)
                        )
                    ),
                "Old Block"
            );
            require(
                headerTree[validationParams.parentHash].mix != 0,
                "Parent Missing"
            );
            require(
                int256(
                    uint256(
                        uint64(
                            headerTree[validationParams.parentHash].mix >> 128
                        )
                    )
                ) +
                    1 ==
                    validationParams.number,
                "Invalid N"
            );
            require(
                uint64(headerTree[validationParams.parentHash].mix >> 64) <
                    validationParams.roundNumber,
                "Invalid RN"
            );
            require(
                uint64(headerTree[validationParams.parentHash].mix >> 64) ==
                    validationParams.prevRoundNumber,
                "Invalid PRN"
            );

            bytes32 blockHash = keccak256(headers[x]);

            // If block is the INIT_EPOCH block, prepared for validators switch
            if (headerTree[blockHash].mix > 0) {
                revert("Repeated Header");
            }

            // Verify subnet header certificates
            address[] memory signerList = new address[](
                validationParams.sigs.length
            );
            for (uint256 i = 0; i < validationParams.sigs.length; i++) {
                address signer = HeaderReader.recoverSigner(
                    validationParams.signHash,
                    validationParams.sigs[i]
                );
                if (lookup[signer] != true) revert("Invalid Validator");
                signerList[i] = signer;
            }
            (bool isUnique, int256 uniqueCounter) = checkUniqueness(signerList);
            if (!isUnique) {
                revert("Repeated Validator");
            }
            if (uniqueCounter * 100 < currentValidators.threshold) {
                revert("Insufficient Signatures");
            }

            if (current.length > 0 && next.length > 0)
                revert("Malformed Block");
            else if (current.length > 0) {
                if (
                    uint64(uint256(validationParams.number)) % INIT_EPOCH ==
                    0 &&
                    uint64(uint256(validationParams.number)) / INIT_EPOCH ==
                    epochNum + 1
                ) {
                    int256 gapNumber = validationParams.number -
                        (validationParams.number %
                            int256(uint256(INIT_EPOCH))) -
                        int256(uint256(INIT_GAP));
                    // Edge case at the beginning
                    if (gapNumber < 0) {
                        gapNumber = 0;
                    }
                    unchecked {
                        epochNum++;
                        gapNumber++;
                    }

                    if (validators[gapNumber].threshold > 0) {
                        if (
                            !HeaderReader.areListsEqual(
                                validators[gapNumber].set,
                                current
                            )
                        ) {
                            revert("Mismatched Validators");
                        }
                        setLookup(validators[gapNumber].set);
                        currentValidators = validators[gapNumber];
                    } else revert("Missing Current Validators");
                } else {
                    revert("Invalid Current Block");
                }
            } else if (next.length > 0) {
                if (
                    uint64(
                        uint256(
                            validationParams.number %
                                int256(uint256(INIT_EPOCH))
                        )
                    ) ==
                    INIT_EPOCH - INIT_GAP + 1 &&
                    uint64(uint256(validationParams.number)) / INIT_EPOCH ==
                    epochNum
                ) {
                    (bool isValidatorUnique, ) = checkUniqueness(next);
                    if (!isValidatorUnique) revert("Repeated Validator");

                    validators[validationParams.number] = Validators({
                        set: next,
                        threshold: int256((next.length * 2 * 100) / 3)
                    });
                } else revert("Invalid Next Block");
            }

            // Store subnet header
            headerTree[blockHash] = Header({
                receiptHash: validationParams.receiptHash,
                parentHash: validationParams.parentHash,
                mix: (uint256(validationParams.number) << 128) |
                    (uint256(validationParams.roundNumber) << 64) |
                    uint256(uint64(int64(-1)))
            });
            emit SubnetBlockAccepted(blockHash, validationParams.number);
            if (
                validationParams.number >
                int256(uint256(uint64(headerTree[latestBlock].mix >> 128)))
            ) {
                latestBlock = blockHash;
            }

            // Look for commitable ancestor block
            (bool isCommitted, bytes32 committedBlock) = checkCommittedStatus(
                blockHash
            );
            if (!isCommitted) continue;
            latestFinalizedBlock = committedBlock;

            // Confirm all ancestor unconfirmed block
            setCommittedStatus(committedBlock);
        }
    }

    function setLookup(address[] memory validatorSet) internal {
        for (uint256 i = 0; i < currentValidators.set.length; i++) {
            lookup[currentValidators.set[i]] = false;
        }
        for (uint256 i = 0; i < validatorSet.length; i++) {
            lookup[validatorSet[i]] = true;
        }
    }

    /* @dev Confirm all ancestor uncommitted block 
       if mainnetNum is -1, it means the block is uncommitted.
       if mainnetNum is not -1, it means the block is committed.
     * @param startBlock
     * @return void
     */
    function setCommittedStatus(bytes32 startBlock) internal {
        while (
            int64(uint64(headerTree[startBlock].mix)) == -1 && startBlock != 0
        ) {
            headerTree[startBlock].mix = HeaderReader.clearLowest(
                headerTree[startBlock].mix,
                64
            );
            headerTree[startBlock].mix |= block.number;
            committedBlocks[
                int256(uint256(uint64(headerTree[startBlock].mix >> 128)))
            ] = startBlock;
            emit SubnetBlockFinalized(
                startBlock,
                int256(uint256(uint64(headerTree[startBlock].mix >> 128)))
            );
            startBlock = headerTree[startBlock].parentHash;
        }
    }

    function checkUniqueness(
        address[] memory list
    ) internal returns (bool isUnique, int256 uniqueCounter) {
        uniqueCounter = 0;
        isUnique = true;
        for (uint256 i = 0; i < list.length; i++) {
            if (!uniqueAddr[list[i]]) {
                uniqueCounter++;
                uniqueAddr[list[i]] = true;
            } else {
                isUnique = false;
            }
        }
        for (uint256 i = 0; i < list.length; i++) {
            uniqueAddr[list[i]] = false;
        }
    }

    function checkCommittedStatus(
        bytes32 blockHash
    ) internal view returns (bool isCommitted, bytes32 committedBlock) {
        isCommitted = true;
        committedBlock = blockHash;
        for (uint256 i = 0; i < 2; i++) {
            bytes32 prevHash = headerTree[committedBlock].parentHash;

            if (prevHash == 0) {
                isCommitted = false;
                break;
            }

            if (
                uint64(headerTree[committedBlock].mix >> 64) !=
                uint64(headerTree[prevHash].mix >> 64) + uint64(1)
            ) {
                isCommitted = false;
                break;
            } else {
                committedBlock = prevHash;
            }
        }
        committedBlock = headerTree[committedBlock].parentHash;
    }

    /*
     * @param subnet block hash.
     * @return HeaderInfo struct defined above.
     */
    function getHeader(
        bytes32 blockHash
    ) public view returns (HeaderInfo memory) {
        bool finalized = false;
        if (int64(uint64(headerTree[blockHash].mix)) != -1) {
            finalized = true;
        }
        return
            HeaderInfo({
                parentHash: headerTree[blockHash].parentHash,
                number: int256(
                    uint256(uint64(headerTree[blockHash].mix >> 128))
                ),
                roundNum: uint64(headerTree[blockHash].mix >> 64),
                mainnetNum: int64(uint64(headerTree[blockHash].mix)),
                finalized: finalized
            });
    }

    /*
     * @param subnet block number.
     * @return BlockLite struct defined above.
     */
    function getHeaderByNumber(
        int256 number
    ) public view returns (BlockLite memory) {
        if (committedBlocks[number] == 0) {
            int256 blockNum = int256(
                uint256(uint64(headerTree[latestBlock].mix >> 128))
            );
            if (number > blockNum) {
                return BlockLite({hash: bytes32(0), number: 0});
            }
            int256 numGap = blockNum - number;
            bytes32 currHash = latestBlock;
            for (int256 i = 0; i < numGap; i++) {
                currHash = headerTree[currHash].parentHash;
            }
            return
                BlockLite({
                    hash: currHash,
                    number: int256(
                        uint256(uint64(headerTree[currHash].mix >> 128))
                    )
                });
        } else {
            return
                BlockLite({
                    hash: committedBlocks[number],
                    number: int256(
                        uint256(
                            uint64(
                                headerTree[committedBlocks[number]].mix >> 128
                            )
                        )
                    )
                });
        }
    }

    /*
     * @return pair of BlockLite structs defined above.
     */
    function getLatestBlocks()
        public
        view
        returns (BlockLite memory, BlockLite memory)
    {
        return (
            BlockLite({
                hash: latestBlock,
                number: int256(
                    uint256(uint64(headerTree[latestBlock].mix >> 128))
                )
            }),
            BlockLite({
                hash: latestFinalizedBlock,
                number: int256(
                    uint256(uint64(headerTree[latestFinalizedBlock].mix >> 128))
                )
            })
        );
    }

    /*
     * @return Validators struct defined above.
     */
    function getCurrentValidators() public view returns (Validators memory) {
        return currentValidators;
    }
}
