//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {CMTATFactoryRoot} from "./CMTATFactoryRoot.sol";

/**
* @title ERC-173 contract ownership interface
* @notice Declared locally because OpenZeppelin ships no `IERC173`.
* @dev Its interface id is `owner()` XOR `transferOwnership(address)` = `0x7f5828d0`. The interface
* inherits nothing, so `type(IERC173).interfaceId` covers its whole selector set.
*/
interface IERC173 {
    /**
    * @notice Emitted when ownership moves.
    * @param previousOwner Owner before the transfer.
    * @param newOwner Owner after the transfer.
    */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @notice Hands ownership to a new address.
    * @param newOwner Address receiving ownership.
    */
    function transferOwnership(address newOwner) external;

    /**
    * @notice The current owner.
    * @return owner_ Address of the owner.
    */
    function owner() external view returns (address owner_);
}

/**
* @title Single-owner access-control policy for a CMTAT factory
* @notice Answers `CMTATFactoryRoot`'s authorization hook with OpenZeppelin `Ownable2Step`: only the
* owner may deploy. `Ownable2Step` rather than `Ownable`, so a handover cannot lose the factory to a
* mistyped address - the recipient must call `acceptOwnership`.
* @dev WARNING: this policy has exactly one privilege level and therefore CANNOT express separated
* duties. If a deployment needs "this operator may deploy but not administer", or several deployers
* with independently revocable rights, use `CMTATFactoryAccessControl` instead. The two are chosen at
* deployment and are not interchangeable at a deployed address.
* @dev No role constant is declared here, deliberately: a factory on this policy must not publish a
* role identifier it never checks.
*/
abstract contract CMTATFactoryOwnable2Step is Ownable2Step, CMTATFactoryRoot {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @inheritdoc CMTATFactoryRoot
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(CMTATFactoryRoot) returns (bool) {
        return
            interfaceId == type(IERC173).interfaceId ||
            CMTATFactoryRoot.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @inheritdoc CMTATFactoryRoot
    */
    function _authorizeDeployCMTAT() internal view virtual override onlyOwner {}
}
