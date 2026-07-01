# Slither report feedback — v0.4.0

- **Tool:** Slither 0.11.5
- **Command:** `slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks"`
- **Scope:** factory contracts only — **mocks excluded**; `node_modules` and the vendored `CMTAT/` submodule filtered out.

## Result

The filtered checklist is **empty**: Slither finds no issue whose primary location is in the factory's own contracts (`contracts/standard`, `contracts/light`, `contracts/libraries`).

An unfiltered run surfaces detectors that all resolve to dependencies, the CMTAT submodule, or the excluded `contracts/mocks/` test doubles. Each was verified by opening the cited `file:line`; the filtered run returning 0 confirms none are primary-located in the maintained factory code.

| Detector | Severity | Primary location (verified) | Disposition | Reason |
| --- | --- | --- | --- | --- |
| incorrect-return | High | `node_modules/@openzeppelin/contracts/proxy/Proxy.sol` | False positive | OZ proxy `_delegate` uses an assembly `return`; Slither misreads it. Dependency code, not ours. |
| locked-ether | Medium | `contracts/mocks/ReentrancyDeployMock.sol` | Mock-only | `ReentrantInitLogicMock` has `payable` `receive`/`fallback` for the reentrancy test; it is test scaffolding, excluded from the deployed scope. |
| uninitialized-local | Medium | `CMTAT/` submodule | Out of scope | Vendored CMTAT submodule. |
| unused-return | Medium | `node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol` | Out of scope | OZ dependency. |
| shadowing-local | Low | `CMTAT/` submodule | Out of scope | Vendored CMTAT submodule. |
| missing-zero-check | Low | 2× OZ proxies + 2× `contracts/mocks/ReentrancyDeployMock.sol` | Out of scope / Mock-only | The OZ instances are dependency code; the two new ones are address params in the test-only attacker/logic mocks. The factory *does* validate its own zero addresses via `FactoryErrors`. |
| calls-loop | Low | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| assembly | Info | `node_modules` / `CMTAT/` (+1 mock) | Out of scope / Mock-only | Dependency / submodule; the +1 is the mock's `revert` bubbling assembly. |
| pragma | Info | project-wide version list | Cosmetic | Multiple Solidity versions across the dependency tree; not fixable in the factory. |
| dead-code | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| solc-version | Info | project-wide version list | Cosmetic | Caret pragmas in deps; deployment pins `0.8.34`. |
| low-level-calls | Info | `contracts/mocks/ReentrancyDeployMock.sol` | Mock-only | `factory.call(reentrantCall)` in the reentrancy attacker double; test scaffolding only. |
| naming-convention | Info | `node_modules` / `CMTAT/` (+1 mock) | Out of scope / Mock-only | Dependency / submodule; +1 from the mock's `ATTACKER` immutable. |
| too-many-digits | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. |
| unindexed-event-address | Info | `node_modules` / `CMTAT/` | Out of scope | Dependency / submodule. The factory's own `CMTATDeployed` indexes `proxy`, `deployer`, and `id`. |

## Delta from v0.3.0

- The **factory-scoped result is unchanged: 0 findings** (same as v0.3.0 and v0.2.0).
- The only difference in the *unfiltered* view is the new `contracts/mocks/ReentrancyDeployMock.sol` test double added for the NM-2 regression test: it introduces `locked-ether` (1), `low-level-calls` (1), +2 `missing-zero-check`, and +1 each to `assembly` / `naming-convention`. All are mock-only and excluded by the scoped `--filter-paths … ,mocks` run.

## Executive triage

**Nothing to fix.** No Slither finding is exploitable or located in the factory's maintained code. The factory contracts validate their own zero-address inputs (`FactoryErrors.*`) and index their deployment event, so the dependency-level and mock-only detectors do not translate into project issues.
