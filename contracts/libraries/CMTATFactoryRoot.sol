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
    address[] public cmtatsList;
    bool immutable public useCustomSalt;
    uint256 public cmtatCounterId;
    
    /* ==== Internal mapping ======== */
    mapping(uint256 => address) internal cmtats;
    mapping(bytes32 => bool) internal customSaltUsed;
    
    /* ============ Constructor ============ */
    /**
    * @param factoryAdmin admin
    */
    constructor(address factoryAdmin, bool useCustomSalt_) {
        if(factoryAdmin == address(0)){
            revert  FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForFactoryAdmin();
        }
        if(useCustomSalt_){
            useCustomSalt = useCustomSalt_;
        }
        _grantRole(DEFAULT_ADMIN_ROLE, factoryAdmin);
        _grantRole(CMTAT_DEPLOYER_ROLE, factoryAdmin);
    }


    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves the address of a deployed CMTAT proxy by its counter ID.
     *
     * @param cmtatCounterId_ Identifier used to track deployed CMTAT instances.
     *
     * @return proxyAddress The address of the CMTAT proxy corresponding to the given counter ID.
     */
    function CMTATProxyAddress(uint256 cmtatCounterId_) public view virtual returns (address) {
        return cmtats[cmtatCounterId_];
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
     */
    function nextDeploymentSalt() public view virtual returns(bytes32 saltBytes) {
        return keccak256(abi.encodePacked(cmtatCounterId));
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
    * @param deploymentSalt salt for deployment
    * @dev 
    * if useCustomSalt is at false, the salt used is the current value of cmtatCounterId
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
    * @dev Mirrors deployment salt selection without mutating customSaltUsed.
    */
    function _computeDeploymentSalt(bytes32 deploymentSaltInput) internal view virtual returns(bytes32 saltBytes){
        return useCustomSalt ? deploymentSaltInput : nextDeploymentSalt();
    }

    /**
    * @dev Deploy CMTAT proxy and register it in the factory index.
    */
    function _deployAndRegisterProxy(bytes memory bytecode, bytes32 deploymentSalt) internal returns (address cmtatAddress) {
        cmtatAddress = Create2.deploy(0, deploymentSalt, bytecode);
        cmtats[cmtatCounterId] = cmtatAddress;
        emit CMTATDeployed(cmtatAddress, msg.sender, cmtatCounterId, deploymentSalt);
        ++cmtatCounterId;
        cmtatsList.push(cmtatAddress);
    }
}
