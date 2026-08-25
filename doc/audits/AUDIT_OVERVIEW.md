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
| v0.5.0 | Slither 0.11.5 | [slither-report.md](./v0.5.0/slither-report.md) | [feedback](./v0.5.0/slither-report-feedback.md) |
| v0.5.0 | Aderyn 0.6.5 | [aderyn-report.md](./v0.5.0/aderyn-report.md) | [feedback](./v0.5.0/aderyn-report-feedback.md) |
| v0.5.0 | Claude Code (code-quality review, not a security audit) | [CLAUDE_ANALYSIS.md](./v0.5.0/CLAUDE_ANALYSIS.md) | — (verdicts inline) |
| v0.4.0 | Slither 0.11.5 | [slither-report.md](./v0.4.0/slither-report.md) | [feedback](./v0.4.0/slither-report-feedback.md) |
| v0.4.0 | Aderyn 0.6.5 | [aderyn-report.md](./v0.4.0/aderyn-report.md) | [feedback](./v0.4.0/aderyn-report-feedback.md) |
| v0.3.0 | Slither 0.11.5 | [slither-report.md](./v0.3.0/slither-report.md) | [feedback](./v0.3.0/slither-report-feedback.md) |
| v0.3.0 | Aderyn 0.6.5 | [aderyn-report.md](./v0.3.0/aderyn-report.md) | [feedback](./v0.3.0/aderyn-report-feedback.md) |
| v0.3.0 | [Nethermind AuditAgent](https://auditagent.nethermind.io/) (AI) | [audit_agent_report_v0.3.0.pdf](./v0.3.0/audit_agent_report_v0.3.0.pdf) | [feedback](./v0.3.0/audit_agent_report-feedback.md) |
| v0.2.0 | Slither | [slither-report.md](./v0.2.0/slither-report.md) | — |
| v0.2.0 | Aderyn | [aderyn-report.md](./v0.2.0/aderyn-report.md) | — |

All runs **exclude mocks** and exclude dependencies / the CMTAT submodule from scope.

> **Note:** the [Nethermind AuditAgent](https://auditagent.nethermind.io/) scan was performed by an AI-powered
> automated tool, not a formal human-led audit. Its findings are AI-generated leads, independently verified against
> the source in the linked feedback file.

## v0.5.0 results

| Tool | High | Medium | Low | Info | Anything to fix? |
| --- | --- | --- | --- | --- | --- |
| Slither | 0 | 0 | 0 | 0 | **No** — filtered checklist empty. Verified rather than assumed: the filter paths exist, the report cites no dependency, and all 155 unfiltered findings trace to `node_modules/` or `CMTAT/`. |
| Aderyn | 1 | 0 | 5 | 0 | **No** — H-1 is the CREATE2 init-code false positive; of the five Lows, two are by-design, one environment, one a benign OZ pattern, and the one new to this release (**L-4 Empty Block**) is the intended idiom of the v0.5.0 authorization-hook pattern. |

| Review | Vulnerabilities | Quality findings | Anything to fix? |
| --- | --- | --- | --- |
| [Claude Code code-quality review](./v0.5.0/CLAUDE_ANALYSIS.md) | **0** | 23 rows: 10 fixed, 1 revised, 12 deliberately left | **No security fix.** A measured gas saving (-114 gas in the deployment funnel), documentation corrections, and the structural work listed below. |

Scope note: the codebase grew from 12 to 27 in-scope files (413 → 697 nSLOC) this release — five new `Ownable2Step`
deployables plus the per-capability module split. Aderyn's L-2/L-3 instance counts track that file count; L-1
*fell* from 6 to 4 because the role check moved out of five entrypoints into two policy modules. Slither's
factory-scoped result stays **0**.

**Conclusion for v0.5.0: nothing to fix.** This was a code-quality pass, not a vulnerability hunt: no
finding lets an unauthorized party move value, bypass `CMTAT_DEPLOYER_ROLE`, or brick a factory. Two items
are left open for a maintainer decision - `virtual` consistency on internal functions (E-1) and the absence
of a public way to ask whether a one-shot custom salt is still available (H-1). Notable "keep it" verdicts
recorded so they are not re-opened: the concrete CMTAT import used for the initializer selector costs **0
bytes** of deployed bytecode and makes an upstream signature change fail loudly (I-2), and the beacon
factory's zero-implementation fallback is deliberate (H-2).

## v0.4.0 results

| Tool | High | Medium | Low | Info | Anything to fix? |
| --- | --- | --- | --- | --- | --- |
| Slither | 0 | 0 | 0 | 0 | **No** — filtered checklist empty; unfiltered detectors resolve to `node_modules` / `CMTAT/` or the excluded `contracts/mocks/` test doubles. |
| Aderyn | 1 | 0 | 4 | 0 | **No** — H-1 is a false positive (canonical CREATE2 init-code); the four Lows are by-design / environment / benign OZ pattern. (The NM-2 guard transiently added a `nonReentrant`-not-first-modifier Low; it was fixed by reordering `deployCMTAT`'s modifiers to `nonReentrant onlyRole(...)`.) |

**Conclusion for v0.4.0: nothing to fix.** The NM-2 guard's transient `nonReentrant`-not-first-modifier note was resolved by reordering the `deployCMTAT` modifiers; the final Aderyn set matches v0.3.0 (1 High false positive + 4 by-design/environment Lows). See each feedback file.

## Substantive findings addressed (internal review + AuditAgent, v0.4.0)

- **NM-1 (AuditAgent, Low) — counter-mode address prediction is front-runnable.** Accepted as design (custom-salt mode already reserves a per-caller address); clarified with a `WARNING` NatSpec block on `nextDeploymentSalt()` / `computedNextProxyAddress(...)` and a README callout steering integrators to custom salts.
- **NM-2 (AuditAgent, Info) — counter-derived salt reuse under reentrant init.** Hardened by having each concrete factory inherit OZ `ReentrancyGuard` and mark its `deployCMTAT(...)` entrypoint `nonReentrant`; covered by a regression test (`test/UUPS/ReentrancyGuard.test.js` + `contracts/mocks/ReentrancyDeployMock.sol`).

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
  > doc/audits/v0.4.0/slither-report.md
aderyn -x mocks --output doc/audits/v0.4.0/aderyn-report.md
```
