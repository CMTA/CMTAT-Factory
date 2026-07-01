# Audit & Security Overview

> This is a security/analysis **overview**, not a vulnerability-reporting policy. For how to report a
> vulnerability, see the CMTAT [SECURITY.md](https://github.com/CMTA/CMTAT/blob/master/SECURITY.md).
>
> **This project is not audited.** The analyses below are automated static-analysis runs plus internal review.

## Scope

In scope: the factory contracts under `contracts/` (`standard/`, `light/`, `libraries/`). Out of scope:
`node_modules` (OpenZeppelin) and the vendored `CMTAT/` submodule, which carry their own audits/reviews.

## Static-analysis runs

| Version | Tool | Report | Feedback (triage) |
| --- | --- | --- | --- |
| v0.3.0 | Slither 0.11.5 | [slither-report.md](./v0.3.0/slither-report.md) | [feedback](./v0.3.0/slither-report-feedback.md) |
| v0.3.0 | Aderyn 0.6.5 | [aderyn-report.md](./v0.3.0/aderyn-report.md) | [feedback](./v0.3.0/aderyn-report-feedback.md) |
| v0.3.0 | Nethermind AuditAgent (AI) | [audit_agent_report_v0.3.0.pdf](./v0.3.0/audit_agent_report_v0.3.0.pdf) | [feedback](./v0.3.0/audit_agent_report-feedback.md) |
| v0.2.0 | Slither | [slither-report.md](./v0.2.0/slither-report.md) | — |
| v0.2.0 | Aderyn | [aderyn-report.md](./v0.2.0/aderyn-report.md) | — |

All runs **exclude mocks** and exclude dependencies / the CMTAT submodule from scope.

## v0.3.0 results

| Tool | High | Medium | Low | Info | Anything to fix? |
| --- | --- | --- | --- | --- | --- |
| Slither | 0 | 0 | 0 | 0 | **No** — filtered checklist empty; all unfiltered detectors resolve to `node_modules` / `CMTAT/`. |
| Aderyn | 1 | 0 | 4 | 0 | **No** — H-1 is a false positive (canonical CREATE2 init-code); the 4 Lows are by-design / environment / benign OZ pattern. |
| AuditAgent (AI) | 0 | 0 | 1 | 1 | **No** (not exploitable) — both are the deliberate shared counter-derived salt design; hardened in v0.4.0 anyway (NM-1 docs warning steering to custom-salt mode; NM-2 `nonReentrant` on the `deployCMTAT(...)` entrypoints). |

**Conclusion for v0.3.0: nothing to fix.** See each feedback file for the per-finding reasoning, verified against the source.

## Substantive findings fixed (internal review, v0.3.0)

These came from internal review (not the static analyzers) and were fixed in this release:

- **Build break — OpenZeppelin / CMTAT version coupling.** The factory pinned OZ `5.4.0` while the pinned
  CMTAT (`v3.3.0-rc1`) requires `5.6.1`, causing a duplicate `Initializable` compilation error. Fixed by
  aligning OZ to `5.6.1`, and guarded going forward by `npm run check:oz` (run in CI).
- **Redundant storage.** Removed the `cmtats` mapping that duplicated `cmtatsList` (one fewer `SSTORE` per
  deployment); `CMTATProxyAddress(id)` now reads the array with a bounds guard.
- **Redundant event.** Removed the legacy `CMTAT` event, superseded by the richer `CMTATDeployed`.
- **Transparent proxy admin owner** is validated non-zero (`CMTAT_Factory_AddressZeroNotAllowedForProxyAdminOwner`).

## How to reproduce

```bash
# mocks excluded (default)
slither . --checklist --filter-paths "node_modules,CMTAT,test,forge-std,mocks" \
  > doc/audits/v0.3.0/slither-report.md
aderyn -x mocks --output doc/audits/v0.3.0/aderyn-report.md
```
