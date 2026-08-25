//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

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
