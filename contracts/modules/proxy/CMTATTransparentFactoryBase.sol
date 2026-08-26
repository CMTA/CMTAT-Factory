//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {CMTATFactoryBase} from "../core/CMTATFactoryBase.sol";
import {FactoryErrors} from "../../libraries/FactoryErrors.sol";

/**
 * @notice Shared logic for CMTAT transparent proxy factories.
 */
abstract contract CMTATTransparentFactoryBase is CMTATFactoryBase {
    /**
     * @param logic_ contract implementation, cannot be zero
     * @param useCustomSalt_ custom salt with create2 or not
     */
    constructor(
        address logic_,
        bool useCustomSalt_
    ) CMTATFactoryBase(logic_, useCustomSalt_) {}

    /**
     * @dev Deploy transparent proxy and push the created CMTAT in the list.
     * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
     * @param proxyAdminOwner Address that will own the ProxyAdmin created by the proxy.
     * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
     * @return cmtat The deployed TransparentUpgradeableProxy.
     */
    function _deployTransparentProxy(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal virtual returns (TransparentUpgradeableProxy cmtat) {
        _checkProxyAdminOwner(proxyAdminOwner);
        bytes32 deploymentSalt = _checkAndDetermineDeploymentSalt(
            deploymentSaltInput
        );
        bytes memory bytecode = _getTransparentProxyBytecode(
            proxyAdminOwner,
            initializerData
        );
        cmtat = _deployTransparentProxyBytecode(bytecode, deploymentSalt);
        return cmtat;
    }

    /**
     * @dev Deploy CMTAT and push the created CMTAT in the list.
     * @param bytecode Transparent proxy creation bytecode, constructor arguments included.
     * @param deploymentSalt Effective salt used by CREATE2.
     * @return cmtat The deployed TransparentUpgradeableProxy.
     */
    function _deployTransparentProxyBytecode(
        bytes memory bytecode,
        bytes32 deploymentSalt
    ) internal virtual returns (TransparentUpgradeableProxy cmtat) {
        address cmtatAddress = _deployAndRegisterProxy(
            bytecode,
            deploymentSalt
        );
        cmtat = TransparentUpgradeableProxy(payable(cmtatAddress));
        return cmtat;
    }

    /**
     * @dev Compute a transparent proxy address for an already-derived effective salt.
     * @param effectiveDeploymentSalt Salt already resolved by the caller.
     * @param proxyAdminOwner Address that will own the ProxyAdmin created by the proxy.
     * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
     * @return cmtatProxy The predicted TransparentUpgradeableProxy address.
     */
    function _computedTransparentProxyAddress(
        bytes32 effectiveDeploymentSalt,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view virtual returns (address cmtatProxy) {
        _checkProxyAdminOwner(proxyAdminOwner);
        return
            _computeCreate2Address(
                _getTransparentProxyBytecode(proxyAdminOwner, initializerData),
                effectiveDeploymentSalt
            );
    }

    /**
     * @dev Compute a transparent proxy address using the same salt selection as deployCMTAT.
     * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
     * @param proxyAdminOwner Address that will own the ProxyAdmin created by the proxy.
     * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
     * @return cmtatProxy The predicted TransparentUpgradeableProxy address.
     */
    function _computedNextTransparentProxyAddress(
        bytes32 deploymentSaltInput,
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view virtual returns (address cmtatProxy) {
        return
            _computedTransparentProxyAddress(
                _computeDeploymentSalt(deploymentSaltInput),
                proxyAdminOwner,
                initializerData
            );
    }

    /**
     * @dev Reverts if the transparent proxy admin owner is zero.
     * @param proxyAdminOwner Address that will own the ProxyAdmin created by the proxy.
     */
    function _checkProxyAdminOwner(
        address proxyAdminOwner
    ) internal pure virtual {
        if (proxyAdminOwner == address(0)) {
            revert FactoryErrors
                .CMTAT_Factory_AddressZeroNotAllowedForProxyAdminOwner();
        }
    }

    /**
     * @dev return the transparent proxy bytecode
     * @param proxyAdminOwner Address that will own the ProxyAdmin created by the proxy.
     * @param initializerData Encoded CMTAT initializer call forwarded to the proxy.
     * @return bytecode Transparent proxy creation bytecode, constructor arguments included.
     */
    function _getTransparentProxyBytecode(
        address proxyAdminOwner,
        bytes memory initializerData
    ) internal view virtual returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(logic, proxyAdminOwner, initializerData)
        );
    }
}
