//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;


import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {ContractVersion} from "./ContractVersion.sol";
import {CMTATFactoryInvariant} from "./CMTATFactoryInvariant.sol";
import {FactoryErrors} from "./FactoryErrors.sol";
import {ICMTATFactory} from "../interfaces/ICMTATFactory.sol";
/**
* @notice Code common to Beacon, TP and UUPS factory
* @dev Policy-free: this contract decides WHAT is protected (the deployment entrypoint, through
* `onlyCMTATDeployer`) and leaves WHO may do it to the concrete factory, which must implement
* `_authorizeDeployCMTAT`. It deliberately does not inherit an access-control module, so a deployment
* can be role-based (`CMTATFactoryAccessControl`) or single-owner (`Ownable2Step`) without forking it.
*/
abstract contract CMTATFactoryRoot is ContractVersion, CMTATFactoryInvariant, ICMTATFactory {
    /* ============ State Variables ============ */
    /* ==== Public Variables ======== */
    /**
    * @notice List of every CMTAT proxy deployed by this factory, in deployment order
    */
    address[] public override cmtatsList;
    /**
    * @notice If true, the deployer provides the CREATE2 salt, otherwise the salt is derived from cmtatCounterId
    */
    bool immutable public override useCustomSalt;
    /**
    * @notice Number of CMTAT proxies deployed, also the id assigned to the next deployment
    */
    uint256 public override cmtatCounterId;
    
    /* ==== Internal mapping ======== */
    /**
    * @dev Tracks custom salts already consumed, since a custom salt is one-time-use
    */
    mapping(bytes32 => bool) internal customSaltUsed;
    
    /* ============ Modifiers ============ */
    /**
    * @notice Restricts a function to callers the concrete factory authorizes to deploy.
    * @dev Delegates the decision to `_authorizeDeployCMTAT`, which each deployment implements.
    */
    modifier onlyCMTATDeployer() {
        _authorizeDeployCMTAT();
        _;
    }

    /* ============ Constructor ============ */
    /**
    * @param useCustomSalt_ if true, the salt provided by the deployer is used, otherwise the salt is derived from the deployment counter
    */
    constructor(bool useCustomSalt_) {
        useCustomSalt = useCustomSalt_;
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
    function CMTATProxyAddress(uint256 cmtatCounterId_) public view virtual override returns (address) {
        return cmtatCounterId_ < cmtatsList.length ? cmtatsList[cmtatCounterId_] : address(0);
    }

    /**
    * @inheritdoc ContractVersion
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ContractVersion)
        returns (bool)
    {
        return
            interfaceId == type(ICMTATFactory).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function nextDeploymentSalt() public view virtual override returns(bytes32 saltBytes) {
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
    function isCustomSaltUsed(bytes32 salt) public view virtual override returns (bool used) {
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
    function _deployAndRegisterProxy(bytes memory bytecode, bytes32 deploymentSalt) internal virtual returns (address cmtatAddress) {
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

    /**
    * @notice Authorization hook invoked before any CMTAT deployment.
    * @dev Declared without a body on purpose: a concrete factory cannot be deployed until it states
    * its access-control policy. Implementations revert when the caller is not authorized, and are
    * expected to be a bare override carrying only a modifier, e.g.
    * `function _authorizeDeployCMTAT() internal view virtual override onlyRole(CMTAT_DEPLOYER_ROLE) {}`.
    */
    function _authorizeDeployCMTAT() internal view virtual;

    /**
    * @dev Predict the CREATE2 address of a proxy without deploying it.
    * @dev Counterpart of `_deployAndRegisterProxy`, and takes the same two arguments in the same
    * order. Feeding the two a different bytecode or a different effective salt is what makes a
    * prediction stop matching the deployment it claims to describe, so keep the callers of both in
    * sync when changing the proxy type, its constructor arguments, or the initializer payload.
    * @param bytecode Proxy creation bytecode, constructor arguments included.
    * @param deploymentSalt Effective salt used by CREATE2.
    * @return cmtatProxy The address the proxy would occupy.
    */
    function _computeCreate2Address(
        bytes memory bytecode,
        bytes32 deploymentSalt
    ) internal view virtual returns (address cmtatProxy) {
        return Create2.computeAddress(deploymentSalt, keccak256(bytecode), address(this));
    }
}
