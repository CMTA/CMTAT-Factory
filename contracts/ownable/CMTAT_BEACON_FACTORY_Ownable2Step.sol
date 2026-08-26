//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CMTATStandardBeaconFactoryBase} from "../modules/deployment/CMTATStandardBeaconFactoryBase.sol";
import {CMTATFactoryOwnable2Step} from "../modules/access/CMTATFactoryOwnable2Step.sol";
import {CMTATFactoryRoot} from "../modules/core/CMTATFactoryRoot.sol";


/**
 * @notice Factory to deploy CMTAT behind a beacon proxy, gated by a single owner.
 * @dev Single-owner variant of `CMTAT_BEACON_FACTORY`, sharing its deployment logic and differing only in
 * policy. Ownership moves in two steps: `transferOwnership` then `acceptOwnership`.
 * @dev WARNING: one privilege level only - the owner may deploy and administer. If a deployment needs
 * separated duties, use `CMTAT_BEACON_FACTORY`. The choice is made at deployment and cannot be changed at a
 * deployed address.
 */
contract CMTAT_BEACON_FACTORY_Ownable2Step is
    CMTATStandardBeaconFactoryBase,
    CMTATFactoryOwnable2Step
{
    /**
     * @param implementation_ Address of the initial CMTAT implementation contract; if zero, a fresh one is deployed
     * @param beaconOwner Address that will own and control the beacon upgrades
     * @param initialOwner the only address allowed to deploy, cannot be zero
     * @param useCustomSalt_ custom salt with create2 or not
     */
    constructor(
        address implementation_,
        address initialOwner,
        address beaconOwner,
        bool useCustomSalt_
    )
        CMTATStandardBeaconFactoryBase(
            implementation_,
            beaconOwner,
            useCustomSalt_
        )
        Ownable(initialOwner)
    {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc CMTATFactoryOwnable2Step
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(CMTATFactoryOwnable2Step, CMTATFactoryRoot)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
