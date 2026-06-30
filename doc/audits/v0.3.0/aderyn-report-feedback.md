# Aderyn report feedback — v0.3.0

- **Tool:** Aderyn 0.6.5
- **Command:** `aderyn -x mocks --output doc/audits/v0.3.0/aderyn-report.md`
- **Scope:** 12 factory contracts (`contracts/`, 412 nSLOC) — **mocks excluded**.
- **Result:** 1 High · 0 Medium · 4 Low · 0 Informational.

## Per-finding triage

| ID | Severity | Instances | Disposition | Reason (verified against source) |
| --- | --- | --- | --- | --- |
| H-1 | High | 3 | **False positive** | `abi.encodePacked(type(Proxy).creationCode, abi.encode(args))` is the canonical CREATE2 init-code layout (raw creation bytecode followed by ABI-encoded constructor args). It is *not* the dangerous case the detector targets: the constructor args go through `abi.encode` (padded, unambiguous), so no two argument sets collide. `abi.encode`-ing the whole thing would produce **invalid init code** that CREATE2 cannot deploy. Same encoding is used by both `deployCMTAT` and `computedProxyAddress`, keeping prediction and deployment in sync. |
| L-1 | Low | 6 | **By design** | `deployCMTAT` is intentionally gated by `onlyRole(CMTAT_DEPLOYER_ROLE)`, and the factory inherits OZ `AccessControl`. This permissioned deployment model is the documented design (see README "Access control"); it is not a vulnerability. |
| L-2 | Low | 11 | **By design / cosmetic** | `pragma solidity ^0.8.20;` is a deliberate caret range so the contracts can be imported as a library across compiler versions (matching upstream CMTAT). The actual build pins a single compiler (`0.8.34`) in `hardhat.config.js`, so deployed bytecode is deterministic. |
| L-3 | Low | 12 | **Environment** | PUSH0 (emitted from 0.8.20+ targeting Shanghai+) may be unsupported on some L2s. `hardhat.config.js` explicitly sets `evmVersion: 'prague'`; selecting an EVM target compatible with the destination chain is a deploy-time decision, not a code defect. |
| L-4 | Low | 2 | **False positive** | `_grantRole(DEFAULT_ADMIN_ROLE, factoryAdmin)` / `_grantRole(CMTAT_DEPLOYER_ROLE, factoryAdmin)` in the constructor ignore the returned `bool`. That return only signals whether the role was newly granted; OZ's own `AccessControl`/`Ownable` constructors ignore it during initial setup. No security impact. |

## Delta from v0.2.0

- v0.2.0 Aderyn reported **0 High, 4 Low** (L-1 Centralization, L-2 Unspecific pragma, L-3 PUSH0, L-4 Unused Import).
- v0.3.0: the four Low detectors persist (L-4 is now "Unchecked Return" on `_grantRole` rather than "Unused Import" — the earlier unused import was removed). A new **H-1 (`abi.encodePacked` hash collision)** appears because the shared deployment logic (CREATE2 init-code assembly) was consolidated into the base contracts in this release, exposing the canonical-but-flagged pattern to the detector. It is a false positive (see above).

## Executive triage

**Nothing to fix.** The single High is a false positive on the standard CREATE2 init-code pattern; the four Lows are by-design (permissioned deployment), intentional (caret pragma), environment-dependent (PUSH0/EVM target), or a benign OZ pattern (`_grantRole` return). None is exploitable.
