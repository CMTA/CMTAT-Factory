//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

/**
* @title Reentrancy test doubles for the CMTAT factories
* @notice Test-only contracts that prove the `nonReentrant` guard on
* `CMTATFactoryRoot._deployAndRegisterProxy` blocks a `deployCMTAT` re-entry triggered from a
* proxy's initializer while the outer deployment is still in flight (Nethermind AuditAgent NM-2).
* @dev Excluded from static analysis (the `mocks` folder is filtered by Slither/Aderyn).
*/

/**
* @notice Holds `CMTAT_DEPLOYER_ROLE` and re-enters the factory when armed.
* @dev The re-entry must come from a role holder: routing it through this contract (instead of the
* delegatecall'd logic, whose `msg.sender` would be the half-constructed proxy) ensures the nested
* `deployCMTAT` passes `onlyRole` and is rejected by the reentrancy guard, not by access control.
*/
contract ReentrancyDeployAttacker {
    address public factory;
    bytes public reentrantCall;
    bool public armed;

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
    address private immutable ATTACKER;

    constructor(address attacker_) {
        ATTACKER = attacker_;
    }

    fallback() external payable {
        ReentrancyDeployAttacker(ATTACKER).attack();
    }

    receive() external payable {}
}
