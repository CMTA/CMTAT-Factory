# Slither report feedback — v0.5.0

- **Tool:** Slither 0.11.5
- **Command:** `slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks"`
- **Scope:** factory contracts only — **mocks excluded**, dependencies and the vendored `CMTAT/` submodule filtered out. 159 contracts analyzed with 101 detectors.
- **Result:** **0 High · 0 Medium · 0 Low · 0 Informational** — the filtered checklist is empty.

## Per-finding triage

There is nothing to triage: no detector fires with a primary location inside this repo's maintained contracts.

| Detector | Severity | Instances | Disposition |
| --- | --- | --- | --- |
| — | — | 0 | Nothing reported in scope |

## Scope verification

An empty report deserves more scrutiny than a full one, because a mis-set `--filter-paths` fails *open* in the
other direction (pulling dependencies in) and a mistyped one can silently over-filter. Three checks were run:

1. **The filter matches real directories.** This is a Hardhat project: dependencies live in `node_modules/` and
   the vendored CMTAT is a git submodule at `CMTAT/`. Both entries in the filter list exist — there is no
   Foundry-style `lib/` here, and the command is the one the v0.3.0 and v0.4.0 reports used, so the delta is
   comparable.
2. **The filtered report cites nothing out of scope.** `grep -c 'node_modules/\|CMTAT/contracts/'` on the report
   returns **0**.
3. **The unfiltered run was checked for anything of ours.** `slither . --checklist` with no filter returns
   **155 results**. Every one was traced to its primary location, and all are outside this repo's factory code —
   in `node_modules/@openzeppelin/` or `CMTAT/contracts/`. Our own files appear **only** inside the project-wide
   version lists that the `pragma` and `solc-version` detectors print
   (`contracts/interfaces/ICMTATFactory.sol#L2`, `IERC173.sol#L2`, `IERC8303.sol#L2`) — as list members, never as
   the subject of a finding. That is consistent with, and explains, the filtered result of zero.

Unfiltered detector breakdown, for context only (none of these are the factory's):

| Detector | Severity | Results |
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

## Delta from v0.4.0

- v0.4.0 filtered: **0 findings**. v0.5.0 filtered: **0 findings**. Unchanged.
- The codebase grew substantially this release (12 → 27 in-scope files, 413 → 697 nSLOC: five new `Ownable2Step`
  deployables, the access-control hook split, and the per-capability module reorganisation) and the
  factory-scoped Slither result is **still zero**.
- The unfiltered total moved with the dependency tree (CMTAT `v3.3.0-rc1` → `v3.3.0-rc3`, OpenZeppelin `5.6.1` →
  `5.7.0`), not with this project's code.

## Executive triage

**Nothing to fix.** Slither finds no issue in the factory contracts. The empty result was verified rather than
assumed: the filter paths exist, the report cites no dependency, and every one of the 155 unfiltered findings was
traced to a location outside this repository.
