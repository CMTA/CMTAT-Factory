//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {CMTATFactoryRoot} from "./CMTATFactoryRoot.sol";
import {FactoryErrors} from "../../libraries/FactoryErrors.sol";

/**
* @notice Code common to TP and UUPS Factory
* 
*/
abstract contract CMTATFactoryBase is CMTATFactoryRoot {
    /* ============ State Variables ============ */
    /**
    * @notice Address of the CMTAT implementation contract used by every deployed proxy
    */
    address public immutable logic;
    /* ============ Constructor ============ */
    /**
    * @param logic_ contract implementation
    * @param useCustomSalt_ if true, the salt provided by the deployer is used, otherwise the salt is derived from the deployment counter
    */
    constructor(address logic_, bool useCustomSalt_) CMTATFactoryRoot(useCustomSalt_) {
        if(logic_ == address(0)){
            revert FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForLogicContract();
        }
        logic = logic_;
    }
}
