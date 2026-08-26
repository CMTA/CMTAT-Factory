<!-- ===================== SUMMARY (generated) ===================== -->
# Slither report — v0.5.0

- **Tool:** Slither 0.11.5
- **Command:** `slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks"`
- **Scope:** factory contracts only — **mocks excluded**, dependencies (`node_modules`) and the vendored `CMTAT/` submodule filtered out. 159 contracts analyzed with 101 detectors.
- **Result (factory contracts):** **0 High · 0 Medium · 0 Low · 0 Informational** — the filtered checklist below is empty.

**Nothing to fix.** Slither reports no finding whose primary location is inside the factory's own contracts (`contracts/standard`, `contracts/light`, `contracts/ownable`, `contracts/modules`, `contracts/interfaces`, `contracts/libraries`).

| Detector | Severity | Instances | Assessment |
| --- | --- | --- | --- |
| — | — | 0 | Filtered checklist empty; nothing located in this repo's maintained code |

**Scope check.** An *unfiltered* run (`slither . --checklist`, including dependencies, the CMTAT submodule and the excluded `contracts/mocks/`) returns **155 results** across the detectors below. Each was checked: every finding's primary location is outside this repo's factory code. Our own files appear only as *members of the project-wide version lists* printed by the `pragma` and `solc-version` detectors (`contracts/interfaces/ICMTATFactory.sol#L2`, `IERC173.sol#L2`, `IERC8303.sol#L2`), never as the subject of a finding — which is why the filtered run is empty.

| Detector (unfiltered context) | Severity | Results |
| --- | --- | --- |
| incorrect-return | High | 1 |
| locked-ether | Medium | 1 |
| uninitialized-local | Medium | 1 |
| unused-return | Medium | 2 |
| shadowing-local | Low | 1 |
| missing-zero-check | Low | 5 |
| calls-loop | Low | 16 |
| assembly | Informational | 46 |
| pragma | Informational | 1 |
| dead-code | Informational | 3 |
| solc-version | Informational | 7 |
| low-level-calls | Informational | 1 |
| naming-convention | Informational | 65 |
| too-many-digits | Informational | 2 |
| unindexed-event-address | Informational | 3 |

See [`slither-report-feedback.md`](./slither-report-feedback.md) and the [audit overview](../AUDIT_OVERVIEW.md).

<!-- ===================== RAW SLITHER OUTPUT (filtered) ===================== -->
**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
