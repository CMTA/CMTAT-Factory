//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {UpgradeableBeacon} from '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';
import {CMTATStandardUpgradeable} from "../../CMTAT/contracts/deployment/CMTATStandardUpgradeable.sol";
import {CMTATFactoryRoot} from "../libraries/CMTATFactoryRoot.sol";
import {FactoryErrors} from "../libraries/FactoryErrors.sol";

/**
* @notice Factory to deploy beacon proxy
* 
*/
contract CMTAT_BEACON_FACTORY is CMTATFactoryRoot {
    UpgradeableBeacon public immutable beacon;
    
    /**
     * @notice Deploys a factory that manages CMTAT Beacon proxies.
     * @dev 
     * - Initializes the UpgradeableBeacon with the given `implementation_`.
     * - Assigns `factoryAdmin` as the administrator of this factory.
     * - Transfers beacon ownership to `beaconOwner`.
     * - If `useCustomSalt_` is true, allows deterministic deployments via CREATE2.
     *
     * @param implementation_ Address of the initial CMTAT implementation contract.
     * @param factoryAdmin Address that will control factory-level operations.
     * @param beaconOwner Address that will own and control the beacon upgrades.
     * @param useCustomSalt_ Boolean flag to enable or disable deterministic deployment salt usage.
     */
    constructor(address implementation_, address factoryAdmin, address beaconOwner, bool useCustomSalt_) CMTATFactoryRoot(factoryAdmin, useCustomSalt_) {
        if(beaconOwner == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner();
        }
        if(implementation_ == address(0)){
           // Forwarder is the zero address if no implementation provided
           implementation_ = address(new CMTATStandardUpgradeable(address(0)));
        }
        beacon = new UpgradeableBeacon(implementation_, beaconOwner);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Deploys a CMTAT token implementation behind a Beacon proxy.
     * @dev 
     * - Uses a deterministic deployment salt to ensure predictable contract addresses.
     * - Deploys a BeaconProxy linked to the upgradeable beacon.
     * - Calls the CMTAT initializer using the provided `cmtatArgument`.
     * - Restricted to callers with the `CMTAT_DEPLOYER_ROLE`.
     *
     * @param deploymentSaltInput Salt used for deterministic deployment (via CREATE2).
     * @param cmtatArgument Struct containing initializer arguments for the CMTAT contract.
     *
     * @return cmtat The deployed BeaconProxy instance pointing to the CMTAT implementation.
     */
    function deployCMTAT(
         bytes32 deploymentSaltInput,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument
    ) public virtual onlyRole(CMTAT_DEPLOYER_ROLE) returns(BeaconProxy cmtat)   {
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
    * @return cmtatProxy proxy address
    */
    function computedProxyAddress( 
        bytes32 effectiveDeploymentSalt,
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        bytes memory bytecode =  _getBytecode(
        // CMTAT function initialize
        cmtatArgument);
        return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
    }

    /**
    * @notice get the proxy address using the same salt selection as deployCMTAT
    */
    function computedNextProxyAddress(
        bytes32 deploymentSaltInput,
        CMTAT_ARGUMENT calldata cmtatArgument) public virtual view returns (address cmtatProxy) {
        return computedProxyAddress(
            _computeDeploymentSalt(deploymentSaltInput),
            cmtatArgument
        );
    }

    /**
    * @notice get the implementation address from the beacon
    * @return beaconimplementation Address of the CMTAT implementation contract.
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
        // CMTAT function initialize
        CMTAT_ARGUMENT calldata cmtatArgument) internal view returns(bytes memory bytecode) {
        bytes memory _implementation = abi.encodeWithSelector(
            CMTATStandardUpgradeable(address(0)).initialize.selector,
            cmtatArgument.CMTATAdmin,
            cmtatArgument.ERC20Attributes,
            cmtatArgument.extraInformationAttributes,
            cmtatArgument.engines
        );
        bytecode = abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(address(beacon), _implementation));
     }
}
