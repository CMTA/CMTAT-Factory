//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;


import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {ContractVersion} from "./ContractVersion.sol";
import {CMTATFactoryInvariant} from "./CMTATFactoryInvariant.sol";
import {FactoryErrors} from "./FactoryErrors.sol";
/**
* @notice Code common to Beacon, TP and UUPS factory
*
*/
abstract contract CMTATFactoryRoot is AccessControl, ContractVersion, CMTATFactoryInvariant {
    /* ============ State Variables ============ */
    /* ==== Public Variables ======== */
    /**
    * @notice List of every CMTAT proxy deployed by this factory, in deployment order
    */
    address[] public cmtatsList;
    /**
    * @notice If true, the deployer provides the CREATE2 salt, otherwise the salt is derived from cmtatCounterId
    */
    bool immutable public useCustomSalt;
    /**
    * @notice Number of CMTAT proxies deployed, also the id assigned to the next deployment
    */
    uint256 public cmtatCounterId;
    
    /* ==== Internal mapping ======== */
    /**
    * @dev Tracks custom salts already consumed, since a custom salt is one-time-use
    */
    mapping(bytes32 => bool) internal customSaltUsed;
    
    /* ============ Constructor ============ */
    /**
    * @param factoryAdmin admin
    * @param useCustomSalt_ if true, the salt provided by the deployer is used, otherwise the salt is derived from the deployment counter
    */
    constructor(address factoryAdmin, bool useCustomSalt_) {
        if(factoryAdmin == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForFactoryAdmin();
        }
        useCustomSalt = useCustomSalt_;
        _grantRole(DEFAULT_ADMIN_ROLE, factoryAdmin);
        _grantRole(CMTAT_DEPLOYER_ROLE, factoryAdmin);
    }


    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves the address of a deployed CMTAT proxy by its counter ID.
     * @dev The id is the sequential deployment index, independent of the salt used
     * (custom or counter-derived). Returns the zero address for an unknown id.
     *
     * @param cmtatCounterId_ Identifier used to track deployed CMTAT instances.
     *
     * @return proxyAddress The address of the CMTAT proxy corresponding to the given counter ID.
     */
    function CMTATProxyAddress(uint256 cmtatCounterId_) public view virtual returns (address) {
        return cmtatCounterId_ < cmtatsList.length ? cmtatsList[cmtatCounterId_] : address(0);
    }

    /**
    * @inheritdoc AccessControl
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ContractVersion)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the effective salt that will be used for the next deployment when custom salts are disabled.
     * @dev Custom-salt deployments use the caller-provided salt directly.
     * @dev WARNING: this salt is derived from the shared `cmtatCounterId`, so it advances whenever ANY authorized
     * deployer deploys. An address predicted from it is not reserved for a specific caller and can be front-run by
     * another `CMTAT_DEPLOYER_ROLE` holder. For a stable, reservable address prefer custom-salt mode
     * (`useCustomSalt == true`) with a unique caller-chosen salt, which is enforced one-time-use.
     *
     * @return saltBytes The salt the next counter-derived deployment will use.
     */
    function nextDeploymentSalt() public view virtual returns(bytes32 saltBytes) {
        return keccak256(abi.encodePacked(cmtatCounterId));
    }

    /**
     * @notice Tells whether a custom salt has already been consumed by a deployment.
     * @dev A custom salt is one-time-use: once a deployment has used it,
     * `deployCMTAT(...)` with the same salt reverts with `CMTAT_Factory_SaltAlreadyUsed`.
     * `computedProxyAddress(...)` keeps returning the CREATE2 address for a consumed salt, because
     * that address is still what CREATE2 would derive - it just can no longer be reached. Call this
     * before relying on a predicted address to know whether the deployment is still available.
     * @dev Always returns false when `useCustomSalt == false`, since counter mode never records a
     * salt: in that mode the effective salt comes from `nextDeploymentSalt()` and is never reused.
     *
     * @param salt The custom salt to check.
     *
     * @return used True if a deployment already consumed this salt.
     */
    function isCustomSaltUsed(bytes32 salt) public view virtual returns (bool used) {
        return customSaltUsed[salt];
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
    * @param deploymentSalt salt for deployment
    * @dev 
    * if useCustomSalt is at false, the salt used is the current value of cmtatCounterId
    * @return saltBytes The effective salt to use for this deployment.
    */
    function _checkAndDetermineDeploymentSalt(bytes32 deploymentSalt) internal virtual returns(bytes32 saltBytes){
       if(useCustomSalt){
            if(customSaltUsed[deploymentSalt]){
                revert FactoryErrors.CMTAT_Factory_SaltAlreadyUsed();
            }else {
                customSaltUsed[deploymentSalt] = true;
                saltBytes = deploymentSalt;
            }
        }else{
            saltBytes = nextDeploymentSalt();
        }
    }

    /**
    * @dev Deploy CMTAT proxy and register it in the factory index.
    * @dev Reentrancy window: Create2.deploy below runs the proxy constructor (and its CMTAT initializer) BEFORE
    * cmtatCounterId is incremented, so a re-entry into the deploy path could observe the same counter and reuse the
    * same counter-derived salt (Nethermind AuditAgent NM-2). Each concrete factory inherits OpenZeppelin
    * ReentrancyGuard and marks its public deployCMTAT entrypoint `nonReentrant`, which blocks that re-entry.
    * All five factories funnel through this function.
    * @param bytecode Proxy creation bytecode, constructor arguments included.
    * @param deploymentSalt Effective salt used by CREATE2.
    * @return cmtatAddress The address of the deployed CMTAT proxy.
    */
    function _deployAndRegisterProxy(bytes memory bytecode, bytes32 deploymentSalt) internal returns (address cmtatAddress) {
        cmtatAddress = Create2.deploy(0, deploymentSalt, bytecode);
        // cmtatsList index == cmtatCounterId, so the array doubles as the id => address registry.
        uint256 id = cmtatCounterId;
        emit CMTATDeployed(cmtatAddress, msg.sender, id, deploymentSalt);
        cmtatCounterId = id + 1;
        cmtatsList.push(cmtatAddress);
    }

    /**
    * @dev Mirrors deployment salt selection without mutating customSaltUsed.
    * @param deploymentSaltInput Salt supplied by the caller, ignored when useCustomSalt is false.
    * @return saltBytes The effective salt a deployment would use.
    */
    function _computeDeploymentSalt(bytes32 deploymentSaltInput) internal view virtual returns(bytes32 saltBytes){
        return useCustomSalt ? deploymentSaltInput : nextDeploymentSalt();
    }
}
