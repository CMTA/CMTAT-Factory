//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {CMTATUpgradeableLight} from "../CMTAT/contracts/deployment/light/CMTATUpgradeableLight.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {CMTATFactoryBase} from "./libraries/CMTATFactoryBase.sol";

/**
* @notice Factory to deploy CMTAT Light with a transparent proxy
*
*/
contract CMTAT_LIGHT_TP_FACTORY is CMTATFactoryBase {
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
     * @notice Deploys a CMTAT Light token behind a transparent proxy.
     *
     * @param deploymentSaltInput Salt used for deterministic deployment (via CREATE2).
     * @param proxyAdminOwner Address that will own the ProxyAdmin contract.
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT Light contract.
     *
     * @return cmtat proxy Address of the deployed TransparentUpgradeableProxy.
     */
    function deployCMTAT(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument
    ) public virtual onlyRole(CMTAT_DEPLOYER_ROLE) returns(TransparentUpgradeableProxy cmtat)   {
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getBytecode(proxyAdminOwner, cmtatArgument);
        cmtat = _deployBytecode(bytecode,  deploymentSalt);
        return cmtat;
    }

    /**
    * @param deploymentSalt salt for the deployment
    * @param proxyAdminOwner admin of the proxy
    * @param cmtatArgument argument for the function initialize
    * @notice get the proxy address depending on a particular salt
    */
    function computedProxyAddress(
        bytes32 deploymentSalt,
        address proxyAdminOwner,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        bytes memory bytecode =  _getBytecode(proxyAdminOwner, cmtatArgument);
        return Create2.computeAddress(deploymentSalt,  keccak256(bytecode), address(this) );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list
    */
    function _deployBytecode(bytes memory bytecode, bytes32  deploymentSalt) internal returns (TransparentUpgradeableProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
        cmtat = TransparentUpgradeableProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
    * @dev return the smart contract bytecode
    */
    function _getBytecode(
        address proxyAdminOwner,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument) internal view returns(bytes memory bytecode) {
        bytes memory implementation = abi.encodeWithSelector(
            CMTATUpgradeableLight(address(0)).initialize.selector,
            cmtatArgument.CMTATAdmin,
            cmtatArgument.ERC20Attributes
        );
        bytecode = abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(logic, proxyAdminOwner, implementation));
    }
}
