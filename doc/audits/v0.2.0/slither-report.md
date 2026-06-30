**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [pragma](#pragma) (1 results) (Informational)
 - [solc-version](#solc-version) (2 results) (Informational)
## pragma

>  The version set in the config file is 0.8.28

Impact: Informational
Confidence: High
 - [ ] ID-0
	2 different versions of Solidity are used:
	- Version constraint ^0.8.20 is used by:
 		- node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol#4
		- node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#4
		- node_modules/@openzeppelin/contracts/access/AccessControl.sol#4
		- node_modules/@openzeppelin/contracts/access/IAccessControl.sol#4
		- node_modules/@openzeppelin/contracts/access/Ownable.sol#4
		- node_modules/@openzeppelin/contracts/interfaces/IERC1967.sol#4
		- node_modules/@openzeppelin/contracts/interfaces/draft-IERC1822.sol#4
		- node_modules/@openzeppelin/contracts/interfaces/draft-IERC6093.sol#3
		- node_modules/@openzeppelin/contracts/proxy/Proxy.sol#4
		- node_modules/@openzeppelin/contracts/proxy/beacon/IBeacon.sol#4
		- node_modules/@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol#4
		- node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#4
		- node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#4
		- node_modules/@openzeppelin/contracts/utils/Address.sol#4
		- node_modules/@openzeppelin/contracts/utils/Arrays.sol#5
		- node_modules/@openzeppelin/contracts/utils/Comparators.sol#4
		- node_modules/@openzeppelin/contracts/utils/Context.sol#4
		- node_modules/@openzeppelin/contracts/utils/Create2.sol#4
		- node_modules/@openzeppelin/contracts/utils/Errors.sol#4
		- node_modules/@openzeppelin/contracts/utils/Panic.sol#4
		- node_modules/@openzeppelin/contracts/utils/SlotDerivation.sol#5
		- node_modules/@openzeppelin/contracts/utils/StorageSlot.sol#5
		- node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#4
		- node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4
		- node_modules/@openzeppelin/contracts/utils/math/Math.sol#4
		- node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#5
		- CMTAT/contracts/CMTAT_PROXY.sol#3
		- CMTAT/contracts/CMTAT_PROXY_UUPS.sol#3
		- CMTAT/contracts/interfaces/ICCIPToken.sol#3
		- CMTAT/contracts/interfaces/ICMTATConstructor.sol#2
		- CMTAT/contracts/interfaces/ICMTATSnapshot.sol#3
		- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404.sol#3
		- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404EnumCode.sol#3
		- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404Wrapper.sol#3
		- CMTAT/contracts/interfaces/engine/IAuthorizationEngine.sol#3
		- CMTAT/contracts/interfaces/engine/IDebtEngine.sol#3
		- CMTAT/contracts/interfaces/engine/IDebtGlobal.sol#3
		- CMTAT/contracts/interfaces/engine/IRuleEngine.sol#3
		- CMTAT/contracts/interfaces/engine/draft-IERC1643.sol#3
		- CMTAT/contracts/libraries/Errors.sol#3
		- CMTAT/contracts/modules/CMTAT_BASE.sol#3
		- CMTAT/contracts/modules/internal/ERC20SnapshotModuleInternal.sol#3
		- CMTAT/contracts/modules/internal/EnforcementModuleInternal.sol#3
		- CMTAT/contracts/modules/internal/ValidationModuleInternal.sol#3
		- CMTAT/contracts/modules/internal/base/SnapshotModuleBase.sol#3
		- CMTAT/contracts/modules/security/AuthorizationModule.sol#3
		- CMTAT/contracts/modules/wrapper/controllers/ValidationModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/BaseModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/ERC20BaseModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/ERC20BurnModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/ERC20MintModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/EnforcementModule.sol#3
		- CMTAT/contracts/modules/wrapper/core/PauseModule.sol#3
		- CMTAT/contracts/modules/wrapper/extensions/DebtModule.sol#3
		- CMTAT/contracts/modules/wrapper/extensions/DocumentModule.sol#3
		- CMTAT/contracts/modules/wrapper/extensions/ERC20SnapshotModule.sol#3
		- CMTAT/contracts/modules/wrapper/extensions/MetaTxModule.sol#3
		- contracts/CMTAT_BEACON_FACTORY.sol#2
		- contracts/CMTAT_TP_FACTORY.sol#2
		- contracts/CMTAT_UUPS_FACTORY.sol#2
		- contracts/libraries/CMTATFactoryBase.sol#2
		- contracts/libraries/CMTATFactoryInvariant.sol#2
		- contracts/libraries/CMTATFactoryRoot.sol#2
		- contracts/libraries/FactoryErrors.sol#3
	- Version constraint ^0.8.22 is used by:
 		- node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#4
		- node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol#4
		- node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol#4
		- node_modules/@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol#4
		- node_modules/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol#4
		- node_modules/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol#4

## solc-version

> The version set in the config file is 0.8.28

Impact: Informational
Confidence: High
 - [ ] ID-1
Version constraint ^0.8.22 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication.
 It is used by:
	- node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#4
	- node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol#4
	- node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol#4
	- node_modules/@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol#4
	- node_modules/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol#4
	- node_modules/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol#4

 - [ ] ID-2
	Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
	 It is used by:
	- node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol#4
	- node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#4
	- node_modules/@openzeppelin/contracts/access/AccessControl.sol#4
	- node_modules/@openzeppelin/contracts/access/IAccessControl.sol#4
	- node_modules/@openzeppelin/contracts/access/Ownable.sol#4
	- node_modules/@openzeppelin/contracts/interfaces/IERC1967.sol#4
	- node_modules/@openzeppelin/contracts/interfaces/draft-IERC1822.sol#4
	- node_modules/@openzeppelin/contracts/interfaces/draft-IERC6093.sol#3
	- node_modules/@openzeppelin/contracts/proxy/Proxy.sol#4
	- node_modules/@openzeppelin/contracts/proxy/beacon/IBeacon.sol#4
	- node_modules/@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol#4
	- node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#4
	- node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#4
	- node_modules/@openzeppelin/contracts/utils/Address.sol#4
	- node_modules/@openzeppelin/contracts/utils/Arrays.sol#5
	- node_modules/@openzeppelin/contracts/utils/Comparators.sol#4
	- node_modules/@openzeppelin/contracts/utils/Context.sol#4
	- node_modules/@openzeppelin/contracts/utils/Create2.sol#4
	- node_modules/@openzeppelin/contracts/utils/Errors.sol#4
	- node_modules/@openzeppelin/contracts/utils/Panic.sol#4
	- node_modules/@openzeppelin/contracts/utils/SlotDerivation.sol#5
	- node_modules/@openzeppelin/contracts/utils/StorageSlot.sol#5
	- node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#4
	- node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4
	- node_modules/@openzeppelin/contracts/utils/math/Math.sol#4
	- node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#5
	- CMTAT/contracts/CMTAT_PROXY.sol#3
	- CMTAT/contracts/CMTAT_PROXY_UUPS.sol#3
	- CMTAT/contracts/interfaces/ICCIPToken.sol#3
	- CMTAT/contracts/interfaces/ICMTATConstructor.sol#2
	- CMTAT/contracts/interfaces/ICMTATSnapshot.sol#3
	- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404.sol#3
	- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404EnumCode.sol#3
	- CMTAT/contracts/interfaces/draft-IERC1404/draft-IERC1404Wrapper.sol#3
	- CMTAT/contracts/interfaces/engine/IAuthorizationEngine.sol#3
	- CMTAT/contracts/interfaces/engine/IDebtEngine.sol#3
	- CMTAT/contracts/interfaces/engine/IDebtGlobal.sol#3
	- CMTAT/contracts/interfaces/engine/IRuleEngine.sol#3
	- CMTAT/contracts/interfaces/engine/draft-IERC1643.sol#3
	- CMTAT/contracts/libraries/Errors.sol#3
	- CMTAT/contracts/modules/CMTAT_BASE.sol#3
	- CMTAT/contracts/modules/internal/ERC20SnapshotModuleInternal.sol#3
	- CMTAT/contracts/modules/internal/EnforcementModuleInternal.sol#3
	- CMTAT/contracts/modules/internal/ValidationModuleInternal.sol#3
	- CMTAT/contracts/modules/internal/base/SnapshotModuleBase.sol#3
	- CMTAT/contracts/modules/security/AuthorizationModule.sol#3
	- CMTAT/contracts/modules/wrapper/controllers/ValidationModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/BaseModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/ERC20BaseModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/ERC20BurnModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/ERC20MintModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/EnforcementModule.sol#3
	- CMTAT/contracts/modules/wrapper/core/PauseModule.sol#3
	- CMTAT/contracts/modules/wrapper/extensions/DebtModule.sol#3
	- CMTAT/contracts/modules/wrapper/extensions/DocumentModule.sol#3
	- CMTAT/contracts/modules/wrapper/extensions/ERC20SnapshotModule.sol#3
	- CMTAT/contracts/modules/wrapper/extensions/MetaTxModule.sol#3
	- contracts/CMTAT_BEACON_FACTORY.sol#2
	- contracts/CMTAT_TP_FACTORY.sol#2
	- contracts/CMTAT_UUPS_FACTORY.sol#2
	- contracts/libraries/CMTATFactoryBase.sol#2
	- contracts/libraries/CMTATFactoryInvariant.sol#2
	- contracts/libraries/CMTATFactoryRoot.sol#2
	- contracts/libraries/FactoryErrors.sol#3

