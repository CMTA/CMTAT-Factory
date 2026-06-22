//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {CMTATFactoryRoot} from "./CMTATFactoryRoot.sol";
import {FactoryErrors} from "./FactoryErrors.sol";

/**
* @notice Shared logic for CMTAT beacon proxy factories.
*/
abstract contract CMTATBeaconFactoryBase is CMTATFactoryRoot {
    UpgradeableBeacon public immutable beacon;

    /**
    * @param implementation_ contract implementation used by the beacon
    * @param factoryAdmin admin
    * @param beaconOwner owner of the beacon
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address implementation_,
        address factoryAdmin,
        address beaconOwner,
        bool useCustomSalt_
    ) CMTATFactoryRoot(factoryAdmin, useCustomSalt_) {
        if(beaconOwner == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner();
        }
        beacon = new UpgradeableBeacon(implementation_, beaconOwner);
    }

    /**
    * @notice get the implementation address from the beacon
    * @return beaconimplementation Address of the CMTAT implementation contract.
    */
    function implementation() public virtual view returns (address beaconimplementation) {
        return beacon.implementation();
    }

    /**
    * @dev Deploy beacon proxy and push the created CMTAT in the list.
    */
    function _deployBeaconProxy(
        bytes32 deploymentSaltInput,
        bytes memory initializerData
    ) internal returns (BeaconProxy cmtat) {
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getBeaconProxyBytecode(initializerData);
        cmtat = _deployBeaconProxyBytecode(bytecode, deploymentSalt);
        return cmtat;
    }

    /**
    * @dev Compute a beacon proxy address for an already-derived effective salt.
    */
    function _computedBeaconProxyAddress(
        bytes32 effectiveDeploymentSalt,
        bytes memory initializerData
    ) internal view returns (address cmtatProxy) {
        bytes memory bytecode = _getBeaconProxyBytecode(initializerData);
        return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
    }

    /**
    * @dev Compute a beacon proxy address using the same salt selection as deployCMTAT.
    */
    function _computedNextBeaconProxyAddress(
        bytes32 deploymentSaltInput,
        bytes memory initializerData
    ) internal view returns (address cmtatProxy) {
        return _computedBeaconProxyAddress(
            _computeDeploymentSalt(deploymentSaltInput),
            initializerData
        );
    }

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list.
    */
    function _deployBeaconProxyBytecode(bytes memory bytecode, bytes32 deploymentSalt) internal returns (BeaconProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
        cmtat = BeaconProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
    * @dev return the beacon proxy bytecode
    */
    function _getBeaconProxyBytecode(bytes memory initializerData) internal view returns(bytes memory bytecode) {
        bytecode = abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(beacon), initializerData));
    }
}
