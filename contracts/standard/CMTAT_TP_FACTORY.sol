//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import {CMTATStandardTPFactoryBase} from "../modules/deployment/CMTATStandardTPFactoryBase.sol";
import {CMTATFactoryAccessControl} from "../modules/access/CMTATFactoryAccessControl.sol";
import {CMTATFactoryRoot} from "../modules/core/CMTATFactoryRoot.sol";

/**
* @notice Factory to deploy CMTAT behind a transparent proxy, gated by `CMTAT_DEPLOYER_ROLE`.
* @dev Role-based variant. For a single-owner deployment see `CMTAT_TP_FACTORY_Ownable2Step`; the two are
* chosen at deployment and are not interchangeable at a deployed address.
*/
contract CMTAT_TP_FACTORY is CMTATStandardTPFactoryBase, CMTATFactoryAccessControl {
    /**
    * @param logic_ contract implementation, cannot be zero
    * @param factoryAdmin admin, receives DEFAULT_ADMIN_ROLE and CMTAT_DEPLOYER_ROLE
    * @param useCustomSalt_ custom salt with create2 or not
    */
    constructor(
        address logic_,
        address factoryAdmin,
        bool useCustomSalt_
    )
        CMTATStandardTPFactoryBase(logic_, useCustomSalt_)
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
    ) public view virtual override(CMTATFactoryAccessControl, CMTATFactoryRoot) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
