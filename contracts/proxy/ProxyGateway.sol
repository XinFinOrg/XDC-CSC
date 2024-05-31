// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import {ProxyAdmin, TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ICheckpoint} from "../interfaces/ICheckpoint.sol";

contract ProxyGateway is ProxyAdmin {
    // 0 full | 1 lite
    mapping(uint256 => TransparentUpgradeableProxy) public cscProxies;

    //proxy => version
    mapping(ITransparentUpgradeableProxy => uint256) public version;

    event CreateProxy(TransparentUpgradeableProxy proxy);

    function createProxy(
        address logic,
        bytes memory data
    ) public onlyOwner returns (TransparentUpgradeableProxy) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            logic,
            address(this),
            data
        );
        emit CreateProxy(proxy);
        return proxy;
    }

    function createFullProxy(
        address full,
        address[] memory initialValidatorSet,
        bytes memory gapHeader,
        uint64 initGap,
        uint64 initEpoch,
        int256 gsbn
    ) public onlyOwner returns (TransparentUpgradeableProxy) {
        require(
            address(cscProxies[0]) == address(0),
            "full proxy have been created"
        );
        require(
            keccak256(abi.encodePacked(ICheckpoint(full).MODE())) ==
                keccak256(abi.encodePacked("full")),
            "MODE must be full"
        );

        bytes memory data = abi.encodeWithSignature(
            "init(address[],bytes,uint64,uint64,int256)",
            initialValidatorSet,
            gapHeader,
            initGap,
            initEpoch,
            gsbn
        );
        cscProxies[0] = createProxy(full, data);

        return cscProxies[0];
    }

    function createLiteProxy(
        address lite,
        address[] memory initialValidatorSet,
        bytes memory block1,
        uint64 initGap,
        uint64 initEpoch
    ) public onlyOwner returns (TransparentUpgradeableProxy) {
        require(
            address(cscProxies[1]) == address(0),
            "full proxy have been created"
        );
        require(
            keccak256(abi.encodePacked(ICheckpoint(lite).MODE())) ==
                keccak256(abi.encodePacked("lite")),
            "MODE must be lite"
        );
        bytes memory data = abi.encodeWithSignature(
            "init(address[],bytes,uint64,uint64)",
            initialValidatorSet,
            block1,
            initGap,
            initEpoch
        );
        cscProxies[1] = createProxy(lite, data);

        return cscProxies[1];
    }

    function upgrade(
        ITransparentUpgradeableProxy proxy,
        address implementation
    ) public override {
        super.upgrade(proxy, implementation);
        version[proxy]++;
    }

    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override {
        super.upgradeAndCall(proxy, implementation, data);
        version[proxy]++;
    }
}
