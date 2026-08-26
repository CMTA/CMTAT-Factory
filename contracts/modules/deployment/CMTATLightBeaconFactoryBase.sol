//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {CMTATUpgradeableLight} from "../../../CMTAT/contracts/deployment/light/CMTATUpgradeableLight.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CMTATBeaconFactoryBase} from "../proxy/CMTATBeaconFactoryBase.sol";

/**
 * @notice Beacon proxy (cmtat light) factory logic, without an access-control policy.
 * @dev Holds the deployment entrypoint and address prediction shared by every variant of this
 * factory. It does not decide WHO may deploy: `deployCMTAT` is gated by `onlyCMTATDeployer`, whose
 * hook a concrete contract implements by combining this base with a policy
 * (`CMTATFactoryAccessControl` or `CMTATFactoryOwnable2Step`).
 */
abstract contract CMTATLightBeaconFactoryBase is
    CMTATBeaconFactoryBase,
    ReentrancyGuard
{
    /**
     * @param implementation_ Address of the initial CMTAT implementation contract; if zero, a fresh one is deployed
     * @param beaconOwner Address that will own and control the beacon upgrades
     * @param useCustomSalt_ custom salt with create2 or not
     */
    constructor(
        address implementation_,
        address beaconOwner,
        bool useCustomSalt_
    )
        CMTATBeaconFactoryBase(
            implementation_ == address(0)
                ? address(new CMTATUpgradeableLight())
                : implementation_,
            beaconOwner,
            useCustomSalt_
        )
    {}

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
    )
        public
        virtual
        nonReentrant
        onlyCMTATDeployer
        returns (BeaconProxy cmtat)
    {
        return
            _deployBeaconProxy(
                deploymentSaltInput,
                _initializerData(cmtatArgument)
            );
    }

    /**
     * @param effectiveDeploymentSalt effective salt for the deployment
     * @param cmtatArgument argument for the function initialize
     * @notice get the proxy address depending on a particular effective salt
     * @return cmtatProxy proxy address
     */
    function computedProxyAddress(
        bytes32 effectiveDeploymentSalt,
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument
    ) public view virtual returns (address cmtatProxy) {
        return
            _computedBeaconProxyAddress(
                effectiveDeploymentSalt,
                _initializerData(cmtatArgument)
            );
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
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument
    ) public view virtual returns (address cmtatProxy) {
        return
            _computedNextBeaconProxyAddress(
                deploymentSaltInput,
                _initializerData(cmtatArgument)
            );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev return the CMTAT Light initializer data
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
     * @return initializerData Encoded call to the CMTAT Light initializer.
     */
    function _initializerData(
        CMTAT_LIGHT_ARGUMENT calldata cmtatArgument
    ) internal pure virtual returns (bytes memory initializerData) {
        initializerData = abi.encodeWithSelector(
            CMTATUpgradeableLight(address(0)).initialize.selector,
            cmtatArgument.CMTATAdmin,
            cmtatArgument.ERC20Attributes
        );
    }
}
