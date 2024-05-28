// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import {ReverseHeaderReader as HeaderReader} from "./libraries/ReverseHeaderReader.sol";

contract ReverseFullCheckpoint {
    // Compressed mainnet header information stored on chain
    struct Header {
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptRoot;
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

    string public constant MODE = "reverse full";

    uint64 private epochNum;
    uint64 public INIT_STATUS;
    uint64 public INIT_EPOCH;
    uint64 public INIT_V2ESBN;

    // Event types
    event SubnetBlockAccepted(bytes32 blockHash, int256 number);
    event SubnetBlockFinalized(bytes32 blockHash, int256 number);

    function init(
        bytes memory v2esbnHeader,
        uint64 initEpoch,
        int256 v2esbn
    ) public {
        require(INIT_STATUS == 0, "Already init");

        bytes32 v2esbnHeaderHash = keccak256(v2esbnHeader);

        address[] memory next = HeaderReader.getEpoch(v2esbnHeader);

        require(next.length > 0, "No Epoch Validator Empty");

        HeaderReader.ValidationParams memory v2esbnBlock = HeaderReader
            .getValidationParams(v2esbnHeader);

        require(v2esbnBlock.number == v2esbn, "Invalid Init Block");

        headerTree[v2esbnHeaderHash] = Header({
            receiptRoot: v2esbnBlock.receiptRoot,
            stateRoot: v2esbnBlock.stateRoot,
            transactionsRoot: v2esbnBlock.transactionsRoot,
            parentHash: v2esbnBlock.parentHash,
            mix: (uint256(v2esbnBlock.number) << 128) |
                (uint256(v2esbnBlock.roundNumber) << 64) |
                uint256(block.number)
        });
        validators[v2esbn] = Validators({
            set: next,
            threshold: int256((next.length * 2 * 100) / 3)
        });
        currentValidators = validators[v2esbn];
        setLookup(next);
        latestBlock = v2esbnHeaderHash;
        latestFinalizedBlock = v2esbnHeaderHash;

        committedBlocks[v2esbn] = v2esbnHeaderHash;
        INIT_EPOCH = initEpoch;
        INIT_STATUS = 1;
        INIT_V2ESBN = uint64(int64(v2esbn));
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

            address[] memory next = HeaderReader.getEpoch(headers[x]);

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
            if (uniqueCounter * 100 < currentValidators.threshold) {
                revert("Insufficient Signatures");
            }

            if (
                next.length > 0 &&
                validationParams.prevRoundNumber <
                validationParams.roundNumber -
                    (validationParams.roundNumber % INIT_EPOCH)
            ) {
                setLookup(next);

                validators[validationParams.number] = Validators({
                    set: next,
                    threshold: int256((next.length * 2 * 100) / 3)
                });

                currentValidators = validators[validationParams.number];
            }

            // Store subnet header
            headerTree[blockHash] = Header({
                stateRoot: validationParams.stateRoot,
                transactionsRoot: validationParams.transactionsRoot,
                receiptRoot: validationParams.receiptRoot,
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
