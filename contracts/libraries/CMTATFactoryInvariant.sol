//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;


import {ICMTATConstructor} from "../../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";

/**
* @notice List of Invariant (struct, constant, events)
* 
*/
abstract contract CMTATFactoryInvariant {
    /* ============ Structs ============ */
    struct CMTAT_ARGUMENT{
        address CMTATAdmin;
        ICMTATConstructor.ERC20Attributes ERC20Attributes;
        ICMTATConstructor.ExtraInformationAttributes extraInformationAttributes;
        ICMTATConstructor.Engine engines;
    }
    struct CMTAT_LIGHT_ARGUMENT{
        address CMTATAdmin;
        ICMTATConstructor.ERC20Attributes ERC20Attributes;
    }
    /* ============ State Variables ============ */
    /// @dev Role to deploy CMTAT
    bytes32 public constant CMTAT_DEPLOYER_ROLE = keccak256("CMTAT_DEPLOYER_ROLE");
    /* ============ Events ============ */
    event CMTATDeployed(address indexed proxy, address indexed deployer, uint256 indexed id, bytes32 salt);
}
