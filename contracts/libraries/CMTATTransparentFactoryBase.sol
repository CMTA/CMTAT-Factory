//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {CMTATFactoryBase} from "./CMTATFactoryBase.sol";
import {FactoryErrors} from "./FactoryErrors.sol";

/**
* @notice Shared logic for CMTAT transparent proxy factories.
*/
abstract contract CMTATTransparentFactoryBase is CMTATFactoryBase {
    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(address logic_, address factoryAdmin, bool useCustomSalt_) CMTATFactoryBase(logic_, factoryAdmin, useCustomSalt_) {}

    /**
    * @dev Deploy transparent proxy and push the created CMTAT in the list.
    */
    function _deployTransparentProxy(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal returns (TransparentUpgradeableProxy cmtat) {
        _checkProxyAdminOwner(proxyAdminOwner);
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(deploymentSaltInput);
        bytes memory bytecode = _getTransparentProxyBytecode(proxyAdminOwner, initializerData);
        cmtat = _deployTransparentProxyBytecode(bytecode, deploymentSalt);
        return cmtat;
    }

    /**
    * @dev Compute a transparent proxy address for an already-derived effective salt.
    */
    function _computedTransparentProxyAddress(
        bytes32 effectiveDeploymentSalt,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view returns (address cmtatProxy) {
        _checkProxyAdminOwner(proxyAdminOwner);
        bytes memory bytecode = _getTransparentProxyBytecode(proxyAdminOwner, initializerData);
        return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
    }

    /**
    * @dev Compute a transparent proxy address using the same salt selection as deployCMTAT.
    */
    function _computedNextTransparentProxyAddress(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view returns (address cmtatProxy) {
        return _computedTransparentProxyAddress(
            _computeDeploymentSalt(deploymentSaltInput),
            proxyAdminOwner,
            initializerData
        );
    }

    /**
    * @dev Deploy CMTAT and push the created CMTAT in the list.
    */
    function _deployTransparentProxyBytecode(bytes memory bytecode, bytes32 deploymentSalt) internal returns (TransparentUpgradeableProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(bytecode, deploymentSalt);
        cmtat = TransparentUpgradeableProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
    * @dev Reverts if the transparent proxy admin owner is zero.
    */
    function _checkProxyAdminOwner(address proxyAdminOwner) internal pure {
        if(proxyAdminOwner == address(0)){
            revert FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForProxyAdminOwner();
        }
    }

    /**
    * @dev return the transparent proxy bytecode
    */
    function _getTransparentProxyBytecode(
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view returns(bytes memory bytecode) {
        bytecode = abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(logic, proxyAdminOwner, initializerData));
    }
}
