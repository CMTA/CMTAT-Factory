//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
* @notice ERC-8303 interface exposing the contract version
*/
interface IERC8303 {
    /**
    * @notice Returns the implementation version string.
    * @return version_ The implementation version string.
    */
    function version() external view returns (string memory version_);
}

/**
* @notice ERC-8303 contract version implementation.
*/
abstract contract ContractVersion is ERC165, IERC8303 {
    /* ============ State Variables ============ */
    /**
    * @notice Get the current version of the smart contract.
    */
    string private constant VERSION = "0.4.0";

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    * @inheritdoc IERC8303
    */
    function version() public view virtual override(IERC8303) returns (string memory version_) {
        return VERSION;
    }

    /**
    * @inheritdoc ERC165
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC8303).interfaceId || super.supportsInterface(interfaceId);
    }
}
