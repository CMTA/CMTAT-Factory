//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CMTATUpgradeableUUPS} from "../../../CMTAT/contracts/deployment/CMTATUpgradeableUUPS.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CMTATFactoryBase} from "../core/CMTATFactoryBase.sol";

/**
* @notice UUPS factory logic, without an access-control policy.
* @dev Holds the deployment entrypoint and address prediction shared by every UUPS factory variant.
* It does not decide WHO may deploy: `deployCMTAT` is gated by `onlyCMTATDeployer`, whose hook a
* concrete contract implements by combining this base with a policy
* (`CMTATFactoryAccessControl` or `CMTATFactoryOwnable2Step`).
*/
abstract contract CMTATUUPSFactoryBase is CMTATFactoryBase, ReentrancyGuard {
    /**
    * @param logic_ contract implementation, cannot be zero
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address logic_,
        bool useCustomSalt_
    ) CMTATFactoryBase(logic_, useCustomSalt_) {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
     /**
     * @notice Deploys a CMTAT token implementation behind a UUPS proxy.
     * @dev 
     * - Uses a deterministic deployment salt to ensure predictable contract addresses.
     * - Deploys an ERC1967Proxy pointing to a new CMTAT implementation.
     * - Calls the CMTAT initializer using the provided `cmtatArgument`.
     * - Restricted by the deployment's access-control policy (see `_authorizeDeployCMTAT`).
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
    ) public virtual nonReentrant onlyCMTATDeployer returns(ERC1967Proxy cmtat)   {
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
        return _computeCreate2Address(_getBytecode(cmtatArgument), effectiveDeploymentSalt);
    }

    /**
    * @notice get the proxy address using the same salt selection as deployCMTAT
    * @dev WARNING: in counter mode (`useCustomSalt == false`) this prediction is only valid until the next
    * deployment by ANY authorized deployer, because the salt is the shared `nextDeploymentSalt()`. Do not pre-fund
    * or pre-authorize the returned address in a multi-deployer setup. For a stable, reservable address use
    * custom-salt mode (`useCustomSalt == true`) with a unique caller-chosen salt (one-time-use).
    * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
    * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
    * @return cmtatProxy predicted address of the CMTAT proxy for the next deployment
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
    * @param bytecode Proxy creation bytecode, constructor arguments included.
    * @param deploymentSalt Effective salt used by CREATE2.
    * @return cmtat The deployed ERC1967Proxy.
    */
    function _deployBytecode(bytes memory bytecode, bytes32  deploymentSalt) internal virtual returns (ERC1967Proxy cmtat) {
                    address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
                    cmtat = ERC1967Proxy(payable(cmtatAddress));
                    return cmtat;
     }

    
    /**
    * @dev return the smart contract bytecode
    * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
    * @return bytecode ERC1967Proxy creation bytecode, constructor arguments included.
    */
     function _getBytecode( 
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) internal view virtual returns(bytes memory bytecode) {
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
