//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {CMTATFactoryRoot} from "./CMTATFactoryRoot.sol";
import {FactoryErrors} from "./FactoryErrors.sol";

/**
* @title Role-based access-control policy for a CMTAT factory
* @notice Answers `CMTATFactoryRoot`'s authorization hook with OpenZeppelin `AccessControl`: deploying
* requires `CMTAT_DEPLOYER_ROLE`. This is the policy the five standard factories ship with.
* @dev The role constant lives here, with the layer that enforces it, rather than in a shared base. A
* factory built on a different policy - see the `Ownable2Step` variants - therefore never publishes a
* role identifier it does not check, which would otherwise let an operator grant a privilege that
* authorises nothing with no on-chain signal that it had no effect.
*/
abstract contract CMTATFactoryAccessControl is AccessControl, CMTATFactoryRoot {
    /* ============ State Variables ============ */
    /**
    * @notice Role required to call the factory's deployment entrypoint.
    */
    bytes32 public constant CMTAT_DEPLOYER_ROLE = keccak256("CMTAT_DEPLOYER_ROLE");

    /* ============ Constructor ============ */
    /**
    * @notice Grants the factory admin both the default admin role and the deployer role.
    * @param factoryAdmin Address receiving `DEFAULT_ADMIN_ROLE` and `CMTAT_DEPLOYER_ROLE`.
    */
    constructor(address factoryAdmin) {
        if (factoryAdmin == address(0)) {
            revert FactoryErrors.CMTAT_Factory_AddressZeroNotAllowedForFactoryAdmin();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, factoryAdmin);
        _grantRole(CMTAT_DEPLOYER_ROLE, factoryAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @inheritdoc CMTATFactoryRoot
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, CMTATFactoryRoot) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            CMTATFactoryRoot.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @inheritdoc CMTATFactoryRoot
    */
    function _authorizeDeployCMTAT()
        internal
        view
        virtual
        override
        onlyRole(CMTAT_DEPLOYER_ROLE)
    {}
}
