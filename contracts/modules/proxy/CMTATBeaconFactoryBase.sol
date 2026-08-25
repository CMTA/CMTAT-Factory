//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {CMTATFactoryRoot} from "../core/CMTATFactoryRoot.sol";
import {FactoryErrors} from "../../libraries/FactoryErrors.sol";

/**
* @notice Shared logic for CMTAT beacon proxy factories.
*/
abstract contract CMTATBeaconFactoryBase is CMTATFactoryRoot {
    /**
    * @notice Beacon shared by every BeaconProxy deployed by this factory
    */
    UpgradeableBeacon public immutable beacon;

    /**
    * @param implementation_ contract implementation used by the beacon
    * @param beaconOwner owner of the beacon
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address implementation_,
        address beaconOwner,
        bool useCustomSalt_
    ) CMTATFactoryRoot(useCustomSalt_) {
        if(beaconOwner == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner();
        }
        beacon = new UpgradeableBeacon(implementation_, beaconOwner);
    }

    /**
    * @notice get the implementation address from the beacon
    * @return beaconImplementation Address of the CMTAT implementation contract.
    */
    function implementation() public view virtual returns (address beaconImplementation) {
        return beacon.implementation();
    }

    /**
    * @dev Deploy beacon proxy and push the created CMTAT in the list.
    * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
    * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
    * @return cmtat The deployed BeaconProxy.
    */
    function _deployBeaconProxy(
        bytes32 deploymentSaltInput,
        bytes memory initializerData
    ) internal virtual returns (BeaconProxy cmtat) {
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getBeaconProxyBytecode(initializerData);
        cmtat = _deployBeaconProxyBytecode(bytecode, deploymentSalt);
        return cmtat;
    }

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list.
    * @param bytecode Beacon proxy creation bytecode, constructor arguments included.
    * @param deploymentSalt Effective salt used by CREATE2.
    * @return cmtat The deployed BeaconProxy.
    */
    function _deployBeaconProxyBytecode(bytes memory bytecode, bytes32 deploymentSalt) internal virtual returns (BeaconProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
        cmtat = BeaconProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
    * @dev Compute a beacon proxy address for an already-derived effective salt.
    * @param effectiveDeploymentSalt Salt already resolved by the caller.
    * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
    * @return cmtatProxy The predicted BeaconProxy address.
    */
    function _computedBeaconProxyAddress(
        bytes32 effectiveDeploymentSalt,
        bytes memory initializerData
    ) internal view virtual returns (address cmtatProxy) {
        return _computeCreate2Address(
            _getBeaconProxyBytecode(initializerData),
            effectiveDeploymentSalt
        );
    }

    /**
    * @dev Compute a beacon proxy address using the same salt selection as deployCMTAT.
    * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
    * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
    * @return cmtatProxy The predicted BeaconProxy address.
    */
    function _computedNextBeaconProxyAddress(
        bytes32 deploymentSaltInput,
        bytes memory initializerData
    ) internal view virtual returns (address cmtatProxy) {
        return _computedBeaconProxyAddress(
            _computeDeploymentSalt(deploymentSaltInput),
            initializerData
        );
    }

    /**
    * @dev return the beacon proxy bytecode
    * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
    * @return bytecode Beacon proxy creation bytecode, constructor arguments included.
    */
    function _getBeaconProxyBytecode(bytes memory initializerData) internal view virtual returns(bytes memory bytecode) {
        bytecode = abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(beacon), initializerData));
    }
}
