//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {ICMTATFactory} from "../interfaces/ICMTATFactory.sol";

/**
* @title Interface-only consumer of a CMTAT factory
* @notice Test-only contract proving `ICMTATFactory` is usable on its own: this file imports the
* interface and nothing else - no concrete factory, no CMTAT implementation, no OpenZeppelin - yet
* reads a live factory's registry and salt state. If the interface ever stopped matching the
* factories, this would still compile but the test asserting the values would fail.
* @dev Excluded from static analysis (the `mocks` folder is filtered by Slither/Aderyn).
*/
contract FactoryConsumerMock {
    /**
    * @notice Factory this consumer reads, held only as the shared interface.
    */
    ICMTATFactory public immutable FACTORY;

    /**
    * @param factory Address of any CMTAT factory.
    */
    constructor(address factory) {
        FACTORY = ICMTATFactory(factory);
    }

    /**
    * @notice Reads the whole common surface through the interface in one call.
    * @return counter Deployments so far.
    * @return firstProxy Proxy registered under id 0, or the zero address if none.
    * @return listHeadMatchesRegistry Whether `cmtatsList(0)` agrees with `CMTATProxyAddress(0)`.
    * @return nextSalt The salt the next counter-derived deployment would use.
    * @return custom Whether the factory is in custom-salt mode.
    */
    function readAll()
        external
        view
        returns (
            uint256 counter,
            address firstProxy,
            bool listHeadMatchesRegistry,
            bytes32 nextSalt,
            bool custom
        )
    {
        counter = FACTORY.cmtatCounterId();
        firstProxy = FACTORY.CMTATProxyAddress(0);
        listHeadMatchesRegistry = counter == 0
            ? true
            : FACTORY.cmtatsList(0) == firstProxy;
        nextSalt = FACTORY.nextDeploymentSalt();
        custom = FACTORY.useCustomSalt();
    }

    /**
    * @notice Asks the factory whether a custom salt is still available.
    * @param salt The custom salt to check.
    * @return used True if a deployment already consumed it.
    */
    function isSaltConsumed(bytes32 salt) external view returns (bool used) {
        return FACTORY.isCustomSaltUsed(salt);
    }
}
