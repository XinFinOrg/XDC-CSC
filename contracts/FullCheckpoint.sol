// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import {HeaderReader} from "./libraries/HeaderReader.sol";

contract FullCheckpoint {
    // Compressed subnet header information stored on chain
    struct Header {
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptRoot;
        bytes32 parentHash;
        uint256 mix; // padding 64 | uint64 number | uint64 roundNum | empty
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

    struct Range {
        uint256 lastFinalizedNumber;
        uint256 latestFinalizedNumber;
    }

    Range[] public finalizedRanges;

    mapping(bytes32 => Header) private headerTree;
    mapping(uint64 => bytes32) private heightTree;

    mapping(address => bool) private lookup;
    mapping(address => bool) private uniqueAddr;
    mapping(int256 => Validators) private validators;
    Validators private currentValidators;
    bytes32 private latestBlock;
    bytes32 private latestFinalizedBlock;

    string public constant MODE = "full";

    uint64 public epochNum;
    uint64 public INIT_STATUS;
    uint64 public INIT_GAP;
    uint64 public INIT_EPOCH;

    uint64 public certThreshold = 667;

    // Event types
    event SubnetBlockAccepted(bytes32 blockHash, int256 number);
    event SubnetBlockFinalized(bytes32 blockHash, int256 number);

    function init(
        address[] memory initialValidatorSet,
        bytes memory gapBlockHeader,
        uint64 initGap,
        uint64 initEpoch,
        int256 gsbn
    ) public {
        require(INIT_STATUS == 0, "Already init");
        require(initialValidatorSet.length > 0, "Validator Empty");

        bytes32 gapHeaderHash = keccak256(gapBlockHeader);

        HeaderReader.ValidationParams memory gapBlock = HeaderReader
            .getValidationParams(gapBlockHeader);
        require(gapBlock.number == gsbn, "Invalid Init Block");

        (, address[] memory next) = HeaderReader.getEpoch(gapBlockHeader);

        // If gsbn is 1, directly set the validator to the current one.
        // If gsbn is not 1, configure the current block validator and the next one accordingly.
        // For example, at block 451, set the validator for blocks 0-900 and next to 900-1800.
        if (gsbn == 1) {
            validators[1] = Validators({
                set: initialValidatorSet,
                threshold: int256((initialValidatorSet.length * certThreshold))
            });
            currentValidators = validators[1];
        } else {
            require(
                next.length > 0 &&
                    uint64(uint256(gsbn % int256(uint256(initEpoch)))) ==
                    initEpoch - initGap + 1,
                "No Gap Block"
            );

            validators[gapBlock.number] = Validators({
                set: next,
                threshold: int256((initialValidatorSet.length * certThreshold))
            });
            currentValidators = Validators({
                set: initialValidatorSet,
                threshold: int256((initialValidatorSet.length * certThreshold))
            });
            epochNum = uint64(int64(gapBlock.number)) / initEpoch;
        }

        headerTree[gapHeaderHash] = Header({
            receiptRoot: gapBlock.receiptRoot,
            stateRoot: gapBlock.stateRoot,
            transactionsRoot: gapBlock.transactionsRoot,
            parentHash: gapBlock.parentHash,
            mix: (uint256(gapBlock.number) << 128) |
                (uint256(gapBlock.roundNumber) << 64) |
                0
        });

        heightTree[uint64(uint256(gapBlock.number))] = gapHeaderHash;

        setLookup(initialValidatorSet);
        latestBlock = gapHeaderHash;
        latestFinalizedBlock = gapHeaderHash;
        finalizedRanges.push(
            Range({
                lastFinalizedNumber: 0,
                latestFinalizedNumber: uint256(gapBlock.number)
            })
        );

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
            Header memory header = headerTree[validationParams.parentHash];
            require(header.mix != 0, "Parent Missing");
            require(
                int256(uint256(uint64(header.mix >> 128))) + 1 ==
                    validationParams.number,
                "Invalid N"
            );
            require(
                uint64(header.mix >> 64) < validationParams.roundNumber,
                "Invalid RN"
            );
            require(
                uint64(header.mix >> 64) == validationParams.prevRoundNumber,
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
            if (uniqueCounter * 1000 < currentValidators.threshold) {
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
                        threshold: int256((next.length * certThreshold))
                    });
                } else revert("Invalid Next Block");
            }

            // Store subnet header
            headerTree[blockHash] = Header({
                stateRoot: validationParams.stateRoot,
                transactionsRoot: validationParams.transactionsRoot,
                receiptRoot: validationParams.receiptRoot,
                parentHash: validationParams.parentHash,
                mix: (uint256(validationParams.number) << 128) |
                    (uint256(validationParams.roundNumber) << 64) |
                    0
            });
            heightTree[uint64(uint256(validationParams.number))] = blockHash;
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

            // Confirm all ancestor unconfirmed block
            setCommittedStatus(committedBlock);
            latestFinalizedBlock = committedBlock;
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
     * @param committedBlock
     * @return void
     */
    function setCommittedStatus(bytes32 committedBlock) internal {
        finalizedRanges.push(
            Range({
                lastFinalizedNumber: uint256(
                    uint64(headerTree[latestFinalizedBlock].mix >> 128)
                ),
                latestFinalizedNumber: uint256(
                    uint64(headerTree[committedBlock].mix >> 128)
                )
            })
        );
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
        if (headerTree[blockHash].mix == 0) {
            return (
                HeaderInfo({
                    parentHash: 0,
                    number: 0,
                    roundNum: 0,
                    mainnetNum: -1,
                    finalized: false
                })
            );
        }

        (int256 finalizedNumber, bool isFinalized) = getFinalizedInfo(
            blockHash
        );

        return
            HeaderInfo({
                parentHash: headerTree[blockHash].parentHash,
                number: int256(
                    uint256(uint64(headerTree[blockHash].mix >> 128))
                ),
                roundNum: uint64(headerTree[blockHash].mix >> 64),
                mainnetNum: int64(finalizedNumber),
                finalized: isFinalized
            });
    }

    /*
     * @param subnet block hash.
     * @return state root of the block.
     */
    function getRoots(
        bytes32 blockHash
    )
        public
        view
        returns (
            bytes32 stateRoot,
            bytes32 transactionsRoot,
            bytes32 receiptRoot
        )
    {
        return (
            headerTree[blockHash].stateRoot,
            headerTree[blockHash].transactionsRoot,
            headerTree[blockHash].receiptRoot
        );
    }

    /*
     * @param subnet block number.
     * @return HeaderInfo struct defined above.
     */
    function getHeaderByNumber(
        uint256 number
    ) public view returns (HeaderInfo memory) {
        return getHeader(heightTree[uint64(number)]);
    }

    /**
     * @dev Get the finalized information of a block.
     * @param blockHash  The hash of the block.
     * @return finalizedNumber  The number of the block.
     * @return isFinalized  Whether the block is finalized.
     */
    function getFinalizedInfo(
        bytes32 blockHash
    ) public view returns (int256 finalizedNumber, bool isFinalized) {
        uint256 blockNumber = uint256(uint64(headerTree[blockHash].mix >> 128));
        if (blockNumber != 0) {
            for (uint256 i = 0; i < finalizedRanges.length; i++) {
                if (
                    blockNumber >= finalizedRanges[i].lastFinalizedNumber &&
                    blockNumber <= finalizedRanges[i].latestFinalizedNumber
                ) {
                    return (
                        int256(finalizedRanges[i].latestFinalizedNumber),
                        true
                    );
                }
            }
        }

        return (-1, false);
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
