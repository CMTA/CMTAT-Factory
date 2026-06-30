<!-- ===================== SUMMARY (generated) ===================== -->
# Slither report — v0.3.0

- **Tool:** Slither 0.11.5
- **Command:** `slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks"`
- **Scope:** factory contracts only — **mocks excluded**, dependencies (`node_modules`) and the vendored `CMTAT/` submodule filtered out.
- **Result (factory contracts):** **0 High · 0 Medium · 0 Low · 0 Informational** — the filtered checklist below is empty.

**Nothing to fix.** Slither reports no finding whose primary location is inside the factory's own contracts (`contracts/standard`, `contracts/light`, `contracts/libraries`).

For context, an *unfiltered* run (including dependencies and the CMTAT submodule) surfaces the detectors below — every one is located in `node_modules/@openzeppelin/**` or the `CMTAT/` submodule, i.e. outside this repo's maintained code. This was confirmed by the filtered run returning 0.

| Detector | Severity | Instances (unfiltered) | Primary location | Assessment |
| --- | --- | --- | --- | --- |
| incorrect-return | High | 1 | `node_modules` OZ `Proxy.sol` (assembly `return`) | Out of scope — OZ false positive |
| uninitialized-local | Medium | 1 | `CMTAT/` submodule | Out of scope |
| unused-return | Medium | 2 | `node_modules` OZ `ERC1967Utils` | Out of scope |
| shadowing-local | Low | 1 | `CMTAT/` submodule | Out of scope |
| missing-zero-check | Low | 2 | `node_modules` OZ `TransparentUpgradeableProxy` | Out of scope |
| calls-loop | Low | 8 | `node_modules` / `CMTAT/` | Out of scope |
| assembly | Info | 34 | `node_modules` / `CMTAT/` | Out of scope |
| pragma | Info | 1 | project-wide version list | Cosmetic (multi-version pragma across the dep tree) |
| dead-code | Info | 2 | `node_modules` / `CMTAT/` | Out of scope |
| solc-version | Info | 7 | project-wide version list | Cosmetic |
| naming-convention | Info | 55 | `node_modules` / `CMTAT/` | Out of scope |
| too-many-digits | Info | 2 | `node_modules` / `CMTAT/` | Out of scope |
| unindexed-event-address | Info | 3 | `node_modules` / `CMTAT/` | Out of scope |

See the triage in [`slither-report-feedback.md`](./slither-report-feedback.md) and the [audit overview](../AUDIT_OVERVIEW.md).

<!-- ===================== RAW SLITHER OUTPUT ===================== -->

**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
