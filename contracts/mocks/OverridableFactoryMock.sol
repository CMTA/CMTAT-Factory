//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {CMTAT_UUPS_FACTORY} from "../standard/CMTAT_UUPS_FACTORY.sol";
import {CMTAT_TP_FACTORY} from "../standard/CMTAT_TP_FACTORY.sol";
import {CMTATFactoryRoot} from "../libraries/CMTATFactoryRoot.sol";
import {CMTATTransparentFactoryBase} from "../libraries/CMTATTransparentFactoryBase.sol";

/**
* @title Override guards for the factories' internal extension points
* @notice Test-only subclasses proving that the `virtual` internal functions are genuinely
* overridable AND that each override is actually reached at runtime. A compile-only harness would
* pass even if a subclass silently shadowed a non-virtual member, so each mock leaves evidence the
* test asserts on.
* @dev Excluded from static analysis (the `mocks` folder is filtered by Slither/Aderyn).
*/

/**
* @notice Overrides the deployment funnel every factory routes through.
* @dev `_deployAndRegisterProxy` is the single point where a proxy is created, evented and indexed,
* so it is the extension point a subclass most plausibly wants: extra per-deployment bookkeeping.
*/
contract DeployHookFactoryMock is CMTAT_UUPS_FACTORY {
    /**
    * @notice Number of times the overridden funnel actually ran.
    */
    uint256 public hookCallCount;

    /**
    * @notice Proxy address observed by the override on the last deployment.
    */
    address public lastRegistered;

    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address logic_,
        address factoryAdmin,
        bool useCustomSalt_
    ) CMTAT_UUPS_FACTORY(logic_, factoryAdmin, useCustomSalt_) {}

    /**
    * @inheritdoc CMTATFactoryRoot
    */
    function _deployAndRegisterProxy(
        bytes memory bytecode,
        bytes32 deploymentSalt
    ) internal virtual override returns (address cmtatAddress) {
        cmtatAddress = super._deployAndRegisterProxy(bytecode, deploymentSalt);
        ++hookCallCount;
        lastRegistered = cmtatAddress;
    }
}

/**
* @notice Tightens the transparent proxy admin validation hook.
* @dev Demonstrates the point of making `_checkProxyAdminOwner` overridable: a subclass can demand
* more than a non-zero address without forking the base contract. The hook is `internal pure`, so an
* override must stay `pure` and can only compare against constants.
*/
contract StrictProxyAdminFactoryMock is CMTAT_TP_FACTORY {
    /**
    * @notice Proxy admin owner this factory refuses, on top of the inherited zero-address check.
    */
    address public constant BLOCKED_PROXY_ADMIN_OWNER =
        0x000000000000000000000000000000000000dEaD;

    /**
    * @notice Raised when the proxy admin owner is the blocked address.
    */
    error ProxyAdminOwnerBlocked();

    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address logic_,
        address factoryAdmin,
        bool useCustomSalt_
    ) CMTAT_TP_FACTORY(logic_, factoryAdmin, useCustomSalt_) {}

    /**
    * @inheritdoc CMTATTransparentFactoryBase
    */
    function _checkProxyAdminOwner(address proxyAdminOwner) internal pure virtual override {
        super._checkProxyAdminOwner(proxyAdminOwner);
        if (proxyAdminOwner == BLOCKED_PROXY_ADMIN_OWNER) {
            revert ProxyAdminOwnerBlocked();
        }
    }
}
