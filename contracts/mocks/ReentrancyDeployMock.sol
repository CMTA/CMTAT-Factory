//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

/**
* @title Reentrancy test doubles for the CMTAT factories
* @notice Test-only contracts that prove the `nonReentrant` guard on the factories' public
* `deployCMTAT(...)` entrypoints blocks a `deployCMTAT` re-entry triggered from a proxy's
* initializer while the outer deployment is still in flight (Nethermind AuditAgent NM-2).
* @dev Excluded from static analysis (the `mocks` folder is filtered by Slither/Aderyn).
*/

/**
* @notice Holds `CMTAT_DEPLOYER_ROLE` and re-enters the factory when armed.
* @dev The re-entry must come from a role holder: routing it through this contract (instead of the
* delegatecall'd logic, whose `msg.sender` would be the half-constructed proxy) ensures the nested
* `deployCMTAT` passes `onlyRole` and is rejected by the reentrancy guard, not by access control.
*/
contract ReentrancyDeployAttacker {
    /**
    * @notice Factory the attacker re-enters.
    */
    address public factory;
    /**
    * @notice Encoded `deployCMTAT(...)` calldata replayed against the factory.
    */
    bytes public reentrantCall;
    /**
    * @notice If false, `attack()` returns without re-entering.
    */
    bool public armed;

    /**
    * @notice Set the factory, the re-entrant calldata and whether the attack is armed.
    * @param factory_ Factory the attacker re-enters.
    * @param reentrantCall_ Encoded `deployCMTAT(...)` calldata replayed against the factory.
    * @param armed_ If false, `attack()` returns without re-entering.
    */
    function configure(address factory_, bytes calldata reentrantCall_, bool armed_) external {
        factory = factory_;
        reentrantCall = reentrantCall_;
        armed = armed_;
    }

    /// @dev Invoked (as a normal call) from the proxy initializer during the outer deployment.
    function attack() external {
        if (!armed) {
            return;
        }
        (bool ok, bytes memory ret) = factory.call(reentrantCall);
        if (!ok) {
            // Bubble the inner revert (ReentrancyGuardReentrantCall) up into the constructor.
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
    }
}

/**
* @notice Stands in for the CMTAT implementation ("logic") passed to a factory.
* @dev The factory delegatecalls the CMTAT initialize calldata into this contract during proxy
* construction; there is no matching function, so execution lands in `fallback` and re-enters the
* factory through the attacker. The attacker address is `immutable`, so it is baked into the runtime
* bytecode and remains readable under the proxy's delegatecall.
*/
contract ReentrantInitLogicMock {
    /**
    * @notice Attacker contract called from `fallback` during proxy construction.
    */
    address private immutable ATTACKER;

    /**
    * @notice Bake the attacker address into the runtime bytecode.
    * @param attacker_ Attacker contract called from `fallback` during proxy construction.
    */
    constructor(address attacker_) {
        ATTACKER = attacker_;
    }

    /**
    * @notice Accepts plain ether transfers so the mock can stand in for a payable implementation.
    */
    receive() external payable {}

    /**
    * @notice Catches the delegatecalled CMTAT initializer and re-enters the factory through the attacker.
    */
    fallback() external payable {
        ReentrancyDeployAttacker(ATTACKER).attack();
    }
}
