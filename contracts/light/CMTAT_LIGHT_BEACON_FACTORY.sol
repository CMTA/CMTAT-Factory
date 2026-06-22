//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {UpgradeableBeacon} from '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';
import {CMTATUpgradeableLight} from "../../CMTAT/contracts/deployment/light/CMTATUpgradeableLight.sol";
import {CMTATFactoryRoot} from "../libraries/CMTATFactoryRoot.sol";
import {FactoryErrors} from "../libraries/FactoryErrors.sol";

/**
* @notice Factory to deploy CMTAT Light with a beacon proxy
*
*/
contract CMTAT_LIGHT_BEACON_FACTORY is AccessControl, CMTATFactoryRoot {
    UpgradeableBeacon public immutable beacon;

    /**
     * @notice Deploys a factory that manages CMTAT Light Beacon proxies.
     *
     * @param implementation_ Address of the initial CMTAT Light implementation contract.
     * @param factoryAdmin Address that will control factory-level operations.
     * @param beaconOwner Address that will own and control the beacon upgrades.
     * @param useCustomSalt_ Boolean flag to enable or disable deterministic deployment salt usage.
     */
    constructor(address implementation_, address factoryAdmin, address beaconOwner, bool useCustomSalt_) CMTATFactoryRoot(factoryAdmin, useCustomSalt_) {
        if(beaconOwner == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner();
        }
        if(implementation_ == address(0)){
           implementation_ = address(new CMTATUpgradeableLight());
        }
        beacon = new UpgradeableBeacon(implementation_, beaconOwner);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Deploys a CMTAT Light token behind a Beacon proxy.
     *
     * @param deploymentSaltInput Salt used for deterministic deployment (via CREATE2).
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT Light contract.
     *
     * @return cmtat The deployed BeaconProxy instance pointing to the CMTAT Light implementation.
     */
    function deployCMTAT(
        bytes32 deploymentSaltInput,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument
    ) public virtual onlyRole(CMTAT_DEPLOYER_ROLE) returns(BeaconProxy cmtat)   {
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getBytecode(cmtatArgument);
        cmtat = _deployBytecode(bytecode,  deploymentSalt);
        return cmtat;
    }

    /**
    * @param deploymentSalt salt for the deployment
    * @param cmtatArgument argument for the function initialize
    * @notice get the proxy address depending on a particular salt
    * @return cmtatProxy proxy address
    */
    function computedProxyAddress(
        bytes32 deploymentSalt,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        bytes memory bytecode =  _getBytecode(cmtatArgument);
        return Create2.computeAddress(deploymentSalt,  keccak256(bytecode), address(this) );
    }

    /**
    * @notice get the implementation address from the beacon
    * @return beaconimplementation Address of the CMTAT Light implementation contract.
    */
    function implementation() public virtual view returns (address beaconimplementation) {
        return beacon.implementation();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list
    */
    function _deployBytecode(bytes memory bytecode, bytes32  deploymentSalt) internal returns (BeaconProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
        cmtat = BeaconProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
    * @dev return the smart contract bytecode
    */
    function _getBytecode(
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) internal view returns(bytes memory bytecode) {
        bytes memory implementation_ = abi.encodeWithSelector(
            CMTATUpgradeableLight(address(0)).initialize.selector,
            cmtatArgument.CMTATAdmin,
            cmtatArgument.ERC20Attributes
        );
        bytecode = abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(beacon), implementation_));
    }
}
