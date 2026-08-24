//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;


import {ICMTATConstructor} from "../../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {ICMTATFactory} from "../interfaces/ICMTATFactory.sol";

/**
* @notice List of Invariant (struct, constant, events)
* 
*/
abstract contract CMTATFactoryInvariant is ICMTATFactory {
    /* ============ Structs ============ */
    /**
    * @notice Initializer arguments forwarded to a standard CMTAT implementation
    */
    struct CMTAT_ARGUMENT{
        address CMTATAdmin;
        ICMTATConstructor.ERC20Attributes ERC20Attributes;
        ICMTATConstructor.ExtraInformationAttributes extraInformationAttributes;
        ICMTATConstructor.Engine engines;
    }
    /**
    * @notice Initializer arguments forwarded to a CMTAT Light implementation
    */
    struct CMTAT_LIGHT_ARGUMENT{
        address CMTATAdmin;
        ICMTATConstructor.ERC20Attributes ERC20Attributes;
    }
    /* ============ State Variables ============ */
    /// @dev Role to deploy CMTAT
    bytes32 public constant override CMTAT_DEPLOYER_ROLE = keccak256("CMTAT_DEPLOYER_ROLE");
}
