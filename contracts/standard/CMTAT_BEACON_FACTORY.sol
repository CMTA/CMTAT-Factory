//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {CMTATStandardBeaconFactoryBase} from "../modules/deployment/CMTATStandardBeaconFactoryBase.sol";
import {CMTATFactoryAccessControl} from "../modules/access/CMTATFactoryAccessControl.sol";
import {CMTATFactoryRoot} from "../modules/core/CMTATFactoryRoot.sol";


/**
 * @notice Factory to deploy CMTAT behind a beacon proxy, gated by `CMTAT_DEPLOYER_ROLE`.
 * @dev Role-based variant. For a single-owner deployment see `CMTAT_BEACON_FACTORY_Ownable2Step`; the two are
 * chosen at deployment and are not interchangeable at a deployed address.
 */
contract CMTAT_BEACON_FACTORY is
    CMTATStandardBeaconFactoryBase,
    CMTATFactoryAccessControl
{
    /**
     * @param implementation_ Address of the initial CMTAT implementation contract; if zero, a fresh one is deployed
     * @param beaconOwner Address that will own and control the beacon upgrades
     * @param factoryAdmin admin, receives DEFAULT_ADMIN_ROLE and CMTAT_DEPLOYER_ROLE
     * @param useCustomSalt_ custom salt with create2 or not
     */
    constructor(
        address implementation_,
        address factoryAdmin,
        address beaconOwner,
        bool useCustomSalt_
    )
        CMTATStandardBeaconFactoryBase(
            implementation_,
            beaconOwner,
            useCustomSalt_
        )
        CMTATFactoryAccessControl(factoryAdmin)
    {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC/EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc CMTATFactoryAccessControl
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(CMTATFactoryAccessControl, CMTATFactoryRoot)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
