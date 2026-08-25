//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;


import {ICMTATConstructor} from "../../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";

/**
* @notice Initializer argument structs shared by every CMTAT factory.
* @dev Policy-free on purpose: role constants live with the layer that enforces them
* (`CMTATFactoryAccessControl`), so an `Ownable2Step` variant never inherits a role it does not check.
*/
abstract contract CMTATFactoryInvariant {
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
}
