//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

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
