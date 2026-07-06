//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CMTATUpgradeableUUPS} from "../../CMTAT/contracts/deployment/CMTATUpgradeableUUPS.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CMTATFactoryBase} from "../libraries/CMTATFactoryBase.sol";


/**
* @notice Factory to deploy CMTAT with a UUPS proxy
* 
*/
contract CMTAT_UUPS_FACTORY is CMTATFactoryBase, ReentrancyGuard {
    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(address logic_, address factoryAdmin, bool useCustomSalt_) CMTATFactoryBase(logic_, factoryAdmin,useCustomSalt_){}
       
    
    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
     /**
     * @notice Deploys a CMTAT token implementation behind a UUPS proxy.
     * @dev 
     * - Uses a deterministic deployment salt to ensure predictable contract addresses.
     * - Deploys an ERC1967Proxy pointing to a new CMTAT implementation.
     * - Calls the CMTAT initializer using the provided `cmtatArgument`.
     * - Restricted to callers with the `CMTAT_DEPLOYER_ROLE`.
     *
     * @param deploymentSaltInput Salt used for deterministic deployment (via CREATE2).
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
     *
     * @return cmtat The deployed ERC1967Proxy instance pointing to the CMTAT implementation.
     */
    function deployCMTAT(
        bytes32 deploymentSaltInput,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument
    ) public virtual nonReentrant onlyRole(CMTAT_DEPLOYER_ROLE) returns(ERC1967Proxy cmtat)   {
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getBytecode(
        // CMTAT function initialize
        cmtatArgument);
        cmtat = _deployBytecode(bytecode,  deploymentSalt);
        
        return cmtat;
    }

    /**
    * @param effectiveDeploymentSalt effective salt for the deployment
    * @param cmtatArgument argument for the function initialize
    * @notice get the proxy address depending on a particular effective salt
    * @return cmtatProxy predicted address of the CMTAT proxy for the given salt
    */
    function computedProxyAddress(
        bytes32 effectiveDeploymentSalt,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) public view virtual returns (address cmtatProxy) {
        bytes memory bytecode =  _getBytecode(
        // CMTAT function initialize
        cmtatArgument);
        return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
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
        CMTAT_ARGUMENT calldata cmtatArgument) public view virtual returns (address cmtatProxy) {
        return computedProxyAddress(
            _computeDeploymentSalt(deploymentSaltInput),
            cmtatArgument
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list
    */
    function _deployBytecode(bytes memory bytecode, bytes32  deploymentSalt) internal returns (ERC1967Proxy cmtat) {
                    address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
                    cmtat = ERC1967Proxy(payable(cmtatAddress));
                    return cmtat;
     }

    
    /**
    * @dev return the smart contract bytecode
    */
     function _getBytecode( 
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) internal view returns(bytes memory bytecode) {
        bytes memory implementation = abi.encodeWithSelector(
            CMTATUpgradeableUUPS(address(0)).initialize.selector,
                  cmtatArgument.CMTATAdmin,
                    cmtatArgument.ERC20Attributes,
                cmtatArgument.extraInformationAttributes,
                cmtatArgument.engines
        );
        bytecode = abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(logic, implementation));
     }
}
