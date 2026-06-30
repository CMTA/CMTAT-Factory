# Slither report feedback — v0.3.0

- **Tool:** Slither 0.11.5
- **Command:** `slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks"`
- **Scope:** factory contracts only — **mocks excluded**; `node_modules` and the vendored `CMTAT/` submodule filtered out.

## Result

The filtered checklist is **empty**: Slither finds no issue whose primary location is in the factory's own contracts (`contracts/standard`, `contracts/light`, `contracts/libraries`).

An unfiltered run surfaces detectors that all resolve to dependencies or the submodule. Each was verified by opening the cited `file:line`; the filtered run returning 0 confirms none are primary-located in the factory.

| Detector | Severity | Primary location (verified) | Disposition | Reason |
| --- | --- | --- | --- | --- |
| incorrect-return | High | `node_modules/@openzeppelin/contracts/proxy/Proxy.sol#L42` | False positive | OZ proxy `_delegate` uses an assembly `return`; Slither misreads it. Dependency code, not ours. |
| uninitialized-local | Medium | `CMTAT/contracts/modules/internal/ERC20EnforcementModuleInternal.sol#L90` | Out of scope | Vendored CMTAT submodule. |
| unused-return | Medium | `node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol#L162` | Out of scope | OZ dependency. |
| shadowing-local | Low | `CMTAT/contracts/modules/wrapper/options/ERC2771Module.sol#L19` | Out of scope | Vendored CMTAT submodule. |
| missing-zero-check | Low | `node_modules/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol#L79` | Out of scope | OZ dependency. (The factory *does* validate its own zero addresses via `FactoryErrors`.) |
| calls-loop | Low | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| assembly | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| pragma | Info | project-wide version list | Cosmetic | Multiple Solidity versions exist across the dependency tree; not fixable in the factory. |
| dead-code | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| solc-version | Info | project-wide version list | Cosmetic | Caret pragmas in deps; deployment pins `0.8.34`. |
| naming-convention | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| too-many-digits | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| unindexed-event-address | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. (The factory's own `CMTATDeployed` indexes `proxy`, `deployer`, and `id`.) |

## Delta from v0.2.0

- v0.2.0 reported only `pragma` (1) + `solc-version` (2), Informational, also from the dependency tree.
- v0.3.0 widens the apparent unfiltered set (the CMTAT submodule moved to `v3.3.0-rc1` and OZ to `5.6.1`, which Slither now also walks), but the **factory-scoped result is unchanged: 0 findings**.

## Executive triage

**Nothing to fix.** No Slither finding is exploitable or located in the factory's maintained code. The factory contracts validate their own zero-address inputs (`FactoryErrors.*`) and index their deployment event, so the dependency-level Low/Info detectors do not translate into project issues.
