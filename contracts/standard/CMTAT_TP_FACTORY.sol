//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {CMTATStandardUpgradeable} from "../../CMTAT/contracts/deployment/CMTATStandardUpgradeable.sol";
import {CMTATTransparentFactoryBase} from "../libraries/CMTATTransparentFactoryBase.sol";


/**
* @notice Factory to deploy CMTAT with a transparent proxy
* 
*/
contract CMTAT_TP_FACTORY is CMTATTransparentFactoryBase {

    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(address logic_, address factoryAdmin, bool useCustomSalt_) CMTATTransparentFactoryBase(logic_, factoryAdmin,useCustomSalt_){}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Deploys a CMTAT token implementation behind a transparent proxy, 
     *         along with a new ProxyAdmin contract.
     * @dev 
     * - Uses a deterministic deployment salt to ensure predictable contract addresses.
     * - Deploys a ProxyAdmin contract owned by `proxyAdminOwner`.
     * - Deploys a TransparentUpgradeableProxy pointing to a new CMTAT implementation.
     * - Calls the CMTAT initializer using the provided `cmtatArgument`.
     *
     * @param deploymentSaltInput Salt used for deterministic deployment (via CREATE2).
     * @param proxyAdminOwner Address that will own the ProxyAdmin contract.
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
     *
     * @return cmtat proxy Address of the deployed TransparentUpgradeableProxy.
     */
    function deployCMTAT(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument
    ) public virtual nonReentrant onlyRole(CMTAT_DEPLOYER_ROLE) returns(TransparentUpgradeableProxy cmtat)   {
        return _deployTransparentProxy(deploymentSaltInput, proxyAdminOwner, _initializerData(cmtatArgument));
    }

    /**
    * @param effectiveDeploymentSalt effective salt for the deployment
    * @param proxyAdminOwner admin of the proxy
    * @param cmtatArgument argument for the function initialize
    * @notice get the proxy address depending on a particular effective salt
    * @return cmtatProxy predicted address of the CMTAT proxy for the given salt
    */
    function computedProxyAddress(
        bytes32 effectiveDeploymentSalt,
        address proxyAdminOwner,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        return _computedTransparentProxyAddress(effectiveDeploymentSalt, proxyAdminOwner, _initializerData(cmtatArgument));
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
        address proxyAdminOwner,
        CMTAT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        return _computedNextTransparentProxyAddress(deploymentSaltInput, proxyAdminOwner, _initializerData(cmtatArgument));
    }


    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev return the CMTAT initializer data
    */
     function _initializerData(
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) internal pure returns(bytes memory initializerData) {
        initializerData = abi.encodeWithSelector(
            CMTATStandardUpgradeable(address(0)).initialize.selector,
                  cmtatArgument.CMTATAdmin,
                    cmtatArgument.ERC20Attributes,
                cmtatArgument.extraInformationAttributes,
                cmtatArgument.engines
        );
     }
}
