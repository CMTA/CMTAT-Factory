//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

/**
* @title Integration interface shared by every CMTAT factory
* @notice The deployment registry and salt surface that `CMTAT_UUPS_FACTORY`, `CMTAT_TP_FACTORY`,
* `CMTAT_BEACON_FACTORY`, `CMTAT_LIGHT_TP_FACTORY` and `CMTAT_LIGHT_BEACON_FACTORY` all expose
* identically. Import this to read a factory's index, predict salts, or watch its deployments without
* importing a concrete factory and, with it, the CMTAT implementation and OpenZeppelin.
* @dev This file has no imports on purpose: it depends on neither the CMTAT submodule nor
* OpenZeppelin, so an indexer or integrating contract can compile against it alone.
* @dev Deliberately excluded, and why:
* - `deployCMTAT` / `computedProxyAddress` / `computedNextProxyAddress` are NOT here. Their shapes
*   differ across the family - the Transparent variants take an extra `proxyAdminOwner`, and the
*   Light variants take `CMTAT_LIGHT_ARGUMENT` instead of `CMTAT_ARGUMENT` - and their arguments are
*   CMTAT types, so declaring them would reintroduce the dependency this interface exists to avoid.
*   `deployCMTAT` also returns the concrete proxy type (`ERC1967Proxy` / `TransparentUpgradeableProxy`
*   / `BeaconProxy`) rather than `address`, which a single interface cannot express.
* - Role administration is plain `IAccessControl` and versioning is `IERC8303`; use those standard
*   interfaces rather than having this one redeclare them. Only `CMTAT_DEPLOYER_ROLE` appears here,
*   because the role identifier itself is specific to this project.
*/
interface ICMTATFactory {
    /* ============ Events ============ */

    /**
    * @notice Emitted when a CMTAT proxy is deployed by the factory
    * @param proxy address of the deployed CMTAT proxy
    * @param deployer address which called the deployment function
    * @param id incremental identifier assigned to the deployed proxy
    * @param salt effective salt used by CREATE2 to deploy the proxy
    */
    event CMTATDeployed(
        address indexed proxy,
        address indexed deployer,
        uint256 indexed id,
        bytes32 salt
    );

    /* ============ Functions ============ */

    /**
    * @notice Role required to call the factory's deployment entrypoint.
    * @return role The `CMTAT_DEPLOYER_ROLE` identifier.
    */
    function CMTAT_DEPLOYER_ROLE() external view returns (bytes32 role);

    /**
    * @notice Address of the deployed proxy for a given deployment id.
    * @dev Returns the zero address for an unknown id rather than reverting.
    * @param cmtatCounterId_ Identifier used to track deployed CMTAT instances.
    * @return proxyAddress The CMTAT proxy deployed under that id.
    */
    function CMTATProxyAddress(
        uint256 cmtatCounterId_
    ) external view returns (address proxyAddress);

    /**
    * @notice Number of CMTAT proxies deployed, also the id the next deployment will receive.
    * @return counter The current deployment counter.
    */
    function cmtatCounterId() external view returns (uint256 counter);

    /**
    * @notice Every CMTAT proxy deployed by this factory, in deployment order.
    * @dev The array index equals the deployment id, so it doubles as the id => address registry.
    * @param index Position in the deployment list.
    * @return proxyAddress The CMTAT proxy at that position.
    */
    function cmtatsList(
        uint256 index
    ) external view returns (address proxyAddress);

    /**
    * @notice Whether a custom salt has already been consumed by a deployment.
    * @dev Always false when `useCustomSalt` is false, since counter mode never records a salt.
    * @param salt The custom salt to check.
    * @return used True if a deployment already used this salt, so deploying with it would revert.
    */
    function isCustomSaltUsed(bytes32 salt) external view returns (bool used);

    /**
    * @notice The salt the next counter-derived deployment will use.
    * @dev WARNING: in counter mode this salt is shared, so it advances whenever ANY authorized
    * deployer deploys. An address predicted from it is not reserved for a specific caller.
    * @return saltBytes `keccak256(abi.encodePacked(cmtatCounterId))`.
    */
    function nextDeploymentSalt() external view returns (bytes32 saltBytes);

    /**
    * @notice Whether the caller supplies the CREATE2 salt, or the factory derives it.
    * @return custom True if deployments use a caller-supplied, one-time-use salt.
    */
    function useCustomSalt() external view returns (bool custom);
}
