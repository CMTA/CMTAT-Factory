//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {CMTATUpgradeableLight} from "../../CMTAT/contracts/deployment/light/CMTATUpgradeableLight.sol";
import {CMTATBeaconFactoryBase} from "../libraries/CMTATBeaconFactoryBase.sol";

/**
* @notice Factory to deploy CMTAT Light with a beacon proxy
*
*/
contract CMTAT_LIGHT_BEACON_FACTORY is CMTATBeaconFactoryBase {
    /**
     * @notice Deploys a factory that manages CMTAT Light Beacon proxies.
     *
     * @param implementation_ Address of the initial CMTAT Light implementation contract.
     * @param factoryAdmin Address that will control factory-level operations.
     * @param beaconOwner Address that will own and control the beacon upgrades.
     * @param useCustomSalt_ Boolean flag to enable or disable deterministic deployment salt usage.
     */
    constructor(address implementation_, address factoryAdmin, address beaconOwner, bool useCustomSalt_)
        CMTATBeaconFactoryBase(
            implementation_ == address(0) ? address(new CMTATUpgradeableLight()) : implementation_,
            factoryAdmin,
            beaconOwner,
            useCustomSalt_
        ) {}

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
    ) public virtual nonReentrant onlyRole(CMTAT_DEPLOYER_ROLE) returns(BeaconProxy cmtat)   {
        return _deployBeaconProxy(deploymentSaltInput, _initializerData(cmtatArgument));
    }

    /**
    * @param effectiveDeploymentSalt effective salt for the deployment
    * @param cmtatArgument argument for the function initialize
    * @notice get the proxy address depending on a particular effective salt
    * @return cmtatProxy proxy address
    */
    function computedProxyAddress(
        bytes32 effectiveDeploymentSalt,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        return _computedBeaconProxyAddress(effectiveDeploymentSalt, _initializerData(cmtatArgument));
    }

    /**
    * @notice get the proxy address using the same salt selection as deployCMTAT
    * @dev WARNING: in counter mode (`useCustomSalt == false`) this prediction is only valid until the next
    * deployment by ANY authorized deployer, because the salt is the shared `nextDeploymentSalt()`. Do not pre-fund
    * or pre-authorize the returned address in a multi-deployer setup. For a stable, reservable address use
    * custom-salt mode (`useCustomSalt == true`) with a unique caller-chosen salt (one-time-use).
    */
    function computedNextProxyAddress(
        bytes32 deploymentSaltInput,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        return _computedNextBeaconProxyAddress(deploymentSaltInput, _initializerData(cmtatArgument));
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev return the CMTAT Light initializer data
    */
    function _initializerData(
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) internal pure returns(bytes memory initializerData) {
        initializerData = abi.encodeWithSelector(
            CMTATUpgradeableLight(address(0)).initialize.selector,
            cmtatArgument.CMTATAdmin,
            cmtatArgument.ERC20Attributes
        );
    }
}
