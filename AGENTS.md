# AI Agent Guide for CMTAT Factory

This file helps AI agents understand and work with this codebase.

`AGENTS.md` and `CLAUDE.md` must always stay identical.

## Project Summary

**CMTAT Factory** is a Solidity/Hardhat project for deploying [CMTAT](https://github.com/CMTA/CMTAT) tokens through three upgradeable proxy patterns:

- `CMTAT_UUPS_FACTORY` for UUPS proxies
- `CMTAT_TP_FACTORY` for Transparent proxies
- `CMTAT_BEACON_FACTORY` for Beacon proxies

The factories deploy token proxies with `CREATE2`, track deployed instances by incremental id, and gate deployment behind `AccessControl`.

- **Factory version:** `0.2.0` in `contracts/libraries/CMTATFactoryRoot.sol`
- **Solidity:** source files use `^0.8.20`, Hardhat compiles with `0.8.30`
- **EVM target:** `prague`
- **License:** `MPL-2.0`

## Build & Test Commands

```bash
npm install
npm test
npx hardhat test test/UUPS/UUPS.test.js
npx hardhat test test/Transparent/Transparent.test.js
npx hardhat test test/beacon/Beacon.test.js
npm run coverage
npm run docgen
npm run size
npm run lint:js
npm run lint:sol
npm run lint:all:prettier
```

This repo vendors the upstream CMTAT project in the `CMTAT/` directory. Some tests rely on helpers from `CMTAT/test/deploymentUtils.js`, so keep that subtree intact.

## Toolchain Notes

- Framework: Hardhat
- Test stack: Mocha + Chai + `@nomicfoundation/hardhat-network-helpers`
- Upgrade tooling: `@openzeppelin/hardhat-upgrades`
- Solidity libs: OpenZeppelin Contracts `5.4.0` and `@openzeppelin/contracts-upgradeable` `5.4.0`
- Docs/analysis tooling: `solidity-docgen`, `surya`, `sol2uml`, `hardhat-contract-sizer`, `solidity-coverage`

## Architecture

### Deployable Contracts

```text
CMTAT_UUPS_FACTORY    - deploys ERC1967Proxy instances pointing at CMTATUpgradeableUUPS
CMTAT_TP_FACTORY      - deploys TransparentUpgradeableProxy instances
CMTAT_BEACON_FACTORY  - deploys BeaconProxy instances backed by one UpgradeableBeacon
```

### Shared Base Contracts

```text
CMTATFactoryInvariant
|- CMTAT_ARGUMENT struct
|- CMTAT_DEPLOYER_ROLE
|- CMTAT event

CMTATFactoryRoot
|- AccessControl
|- VERSION = "0.2.0"
|- cmtatsList / cmtatCounterId / CMTATProxyAddress(id)
|- useCustomSalt
|- _checkAndDetermineDeploymentSalt(...)

CMTATFactoryBase
|- logic immutable
|- shared by UUPS and Transparent factories
```

### Factory Differences

- `CMTAT_UUPS_FACTORY`
  Uses `ERC1967Proxy` and encodes `CMTATUpgradeableUUPS.initialize(...)`.

- `CMTAT_TP_FACTORY`
  Uses `TransparentUpgradeableProxy` and requires `proxyAdminOwner` per deployment.

- `CMTAT_BEACON_FACTORY`
  Creates one `UpgradeableBeacon` in the constructor and deploys `BeaconProxy` instances.
  If `implementation_` is zero, it deploys a fresh `CMTATUpgradeable` implementation internally before creating the beacon.

## Deployment Flow

For all three factories, deployment follows the same high-level sequence:

1. Caller must hold `CMTAT_DEPLOYER_ROLE`.
2. Factory derives the effective salt through `_checkAndDetermineDeploymentSalt`.
3. Factory ABI-encodes proxy creation bytecode plus CMTAT initializer calldata.
4. Factory deploys with `Create2.deploy`.
5. Factory stores the proxy address in `cmtats[id]`, emits `CMTAT(address,id)`, increments `cmtatCounterId`, and appends to `cmtatsList`.

## Salt Behavior

Salt behavior is central to this repo.

- If `useCustomSalt == false`, the deployment salt is `keccak256(abi.encodePacked(cmtatCounterId))`.
- If `useCustomSalt == true`, the caller-supplied salt is used directly.
- Custom salts are one-time-use only and tracked in `customSaltUsed`.
- Reusing a custom salt reverts with `FactoryErrors.CMTAT_Factory_SaltAlreadyUsed()`.

`computedProxyAddress(...)` must mirror the exact bytecode used by `deployCMTAT(...)`. When changing constructor args, proxy type, or initializer payload, update both paths consistently.

## CMTAT Initializer Arguments

The factory passes a nested struct into the CMTAT initializer:

```solidity
struct CMTAT_ARGUMENT {
    address CMTATAdmin;
    ICMTATConstructor.ERC20Attributes ERC20Attributes;
    ICMTATConstructor.ExtraInformationAttributes extraInformationAttributes;
    ICMTATConstructor.Engine engines;
}
```

Tests usually construct this as:

```js
[
  admin,
  ['CMTA Token', 'CMTAT', 0],
  extraInformationAttributes,
  [ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS]
]
```

Be careful when changing field order or tuple encoding, because proxy address prediction depends on the full encoded bytecode.

## Access Control

All factories inherit `AccessControl` through `CMTATFactoryRoot`.

- `DEFAULT_ADMIN_ROLE` is granted to `factoryAdmin` in the constructor.
- `CMTAT_DEPLOYER_ROLE` is also granted to `factoryAdmin` in the constructor.
- `deployCMTAT(...)` is protected by `onlyRole(CMTAT_DEPLOYER_ROLE)`.

There is no separate deployer management wrapper; role administration uses the normal OpenZeppelin `AccessControl` surface.

## Key Errors and Invariants

Custom errors are defined in `contracts/libraries/FactoryErrors.sol`:

- `CMTAT_Factory_AddressZeroNotAllowedForFactoryAdmin`
- `CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner`
- `CMTAT_Factory_AddressZeroNotAllowedForLogicContract`
- `CMTAT_Factory_SaltAlreadyUsed`

Important invariants:

1. UUPS and Transparent factories require a non-zero `logic_` in the constructor.
2. Beacon factory requires a non-zero `beaconOwner`.
3. Beacon factory tolerates `implementation_ == address(0)` by deploying a fallback `CMTATUpgradeable`.
4. Every successful deployment increments `cmtatCounterId` by exactly one.
5. `CMTATProxyAddress(id)` must match the emitted `CMTAT` event and the corresponding entry in `cmtatsList`.
6. Address prediction must stay aligned with the actual deployment bytecode.

## Project Structure

```text
contracts/
|- CMTAT_UUPS_FACTORY.sol
|- CMTAT_TP_FACTORY.sol
|- CMTAT_BEACON_FACTORY.sol
`- libraries/
   |- CMTATFactoryBase.sol
   |- CMTATFactoryRoot.sol
   |- CMTATFactoryInvariant.sol
   `- FactoryErrors.sol

test/
|- UUPS/
|- Transparent/
|- beacon/
`- utils.js

CMTAT/
`- upstream CMTAT project used for implementations, interfaces, and test helpers

doc/
|- audits/
|- schema/
`- script/
```

## Test Conventions

- `test/UUPS/` covers UUPS factory deployment and proxy behavior.
- `test/Transparent/` covers Transparent factory behavior, including custom salt reuse checks.
- `test/beacon/` covers Beacon factory behavior, including zero-implementation fallback.
- Shared constants live in `test/utils.js`.
- Most test fixtures come from `CMTAT/test/deploymentUtils.js`.

When changing shared factory logic in `CMTATFactoryRoot` or `CMTATFactoryInvariant`, update tests across all three factory families.

## Editing Guidance

- Keep `AGENTS.md` and `CLAUDE.md` byte-for-byte equivalent.
- Preserve SPDX headers and pragma style in Solidity files.
- Follow the existing section-header pattern in contracts:
  `/* ============ SECTION ============ */`
- Prefer minimal, targeted changes. The current codebase is small and has duplicated deployment logic by design.
- Be careful with proxy initializer selectors:
  `CMTATUpgradeableUUPS.initialize.selector` is intentionally different from `CMTATUpgradeable.initialize.selector`.
- If you modify proxy creation bytecode, re-check both deployment and `computedProxyAddress(...)`.

## Practical Review Checklist

When working on this repo, verify:

1. Constructor validation still matches the intended proxy type.
2. `deployCMTAT(...)` and `computedProxyAddress(...)` stay in sync.
3. Events, id tracking, and `cmtatsList` updates happen exactly once per deployment.
4. Role gating remains on all deployment entrypoints.
5. Changes do not break the CMTAT initializer tuple shape expected by tests.
