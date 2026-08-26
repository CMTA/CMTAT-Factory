# Aderyn report feedback — v0.5.0

- **Tool:** Aderyn 0.6.5
- **Command:** `aderyn -x mocks --output doc/audits/v0.5.0/aderyn-report.md`
- **Scope:** 27 factory contracts (`contracts/`, 697 nSLOC) — **mocks excluded**.
- **Result:** 1 High · 0 Medium · 5 Low · 0 Informational.

## Per-finding triage

Every cited `file:line` below was opened and checked against the source.

| ID | Severity | Instances | Disposition | Reason (verified against source) |
| --- | --- | --- | --- | --- |
| H-1 | High | 3 | **False positive** | `abi.encodePacked(type(Proxy).creationCode, abi.encode(args))` in `CMTATUUPSFactoryBase.sol:121`, `CMTATBeaconFactoryBase.sol:108` and `CMTATTransparentFactoryBase.sol:107` is the canonical CREATE2 init-code layout (raw creation bytecode followed by ABI-encoded constructor args). It is *not* the case the detector targets: the constructor args go through `abi.encode` (padded, unambiguous), so no two argument sets collide. `abi.encode`-ing the whole thing would produce **invalid init code** that CREATE2 cannot deploy. The same encoding feeds both `deployCMTAT` and `computedProxyAddress`, keeping prediction and deployment in sync. |
| L-1 | Low | 4 | **By design** | Two instances per policy module: the contract declaration and the `_authorizeDeployCMTAT` override, in `CMTATFactoryAccessControl.sol:17,64` and `CMTATFactoryOwnable2Step.sol:20,43`. Deployment is intentionally permissioned — by `CMTAT_DEPLOYER_ROLE` in the role-based variants, by `owner()` in the `Ownable2Step` variants. This is the documented model (see "Access control" in `doc/README.md`), not a vulnerability. |
| L-2 | Low | 26 | **By design / cosmetic** | `pragma solidity ^0.8.20;` is a deliberate caret range so the contracts can be imported as a library across compiler versions (matching upstream CMTAT). The build pins a single compiler (`0.8.36`) in `hardhat.config.js`, so deployed bytecode is deterministic. |
| L-3 | Low | 27 | **Environment** | PUSH0 (emitted from 0.8.20+ targeting Shanghai+) may be unsupported on some L2s. `hardhat.config.js` explicitly sets `evmVersion: 'prague'`; selecting an EVM target compatible with the destination chain is a deploy-time decision, not a code defect. |
| L-4 | Low | 2 | **By design — new in v0.5.0** | `CMTATFactoryAccessControl.sol:59` and `CMTATFactoryOwnable2Step.sol:43` are the two `_authorizeDeployCMTAT` overrides. An empty body is the **intended idiom** of the authorization-hook pattern: the check is carried by the modifier (`onlyRole(CMTAT_DEPLOYER_ROLE)` / `onlyOwner`), which reverts before the body would run. Adding a statement would be dead code. This reads as a declaration of policy rather than as logic, which is the point. See "Access control" in `doc/README.md`. |
| L-5 | Low | 2 | **False positive** | `_grantRole(DEFAULT_ADMIN_ROLE, factoryAdmin)` and `_grantRole(CMTAT_DEPLOYER_ROLE, factoryAdmin)` at `CMTATFactoryAccessControl.sol:33-34` ignore the returned `bool`. That return only signals whether the role was newly granted; OZ's own `AccessControl` / `Ownable` constructors ignore it during initial setup. No security impact. |

## Delta from v0.4.0

| | v0.4.0 | v0.5.0 | Note |
| --- | --- | --- | --- |
| Files / nSLOC | 12 / 413 | 27 / 697 | v0.5.0 doubles the deployable factories (five `Ownable2Step` variants) and splits shared code into per-capability modules |
| High | 1 | 1 | same H-1 false positive; **instance count unchanged at 3** despite the restructure, because the three bytecode builders were consolidated, not multiplied |
| Medium | 0 | 0 | — |
| Low | 4 | 5 | one new: **L-4 Empty Block** |

Movement worth explaining, since the totals grew:

- **L-1 Centralization fell from 6 instances to 4**, even though there are now ten deployable factories instead of
  five. The role check moved out of the five `deployCMTAT` entrypoints into two policy modules, so the detector
  now flags two places instead of five. Fewer instances, identical behaviour.
- **L-2 (11 → 26) and L-3 (12 → 27) track the file count** (12 → 27), one instance per file. Nothing changed about
  the pragma or the EVM target.
- **L-4 Empty Block is new and expected.** It appeared the moment `deployCMTAT`'s inline `onlyRole` was replaced
  by the `_authorizeDeployCMTAT` hook. It is the signature of the pattern, not a regression.
- **L-5 is v0.4.0's L-4 renumbered** (Unchecked Return), unchanged at 2 instances; the insertion of Empty Block as
  L-4 pushed it down one.

No new High or Medium. Nothing became exploitable.

## Executive triage

**Nothing to fix.** The single High is a false positive on the standard CREATE2 init-code pattern. Of the five
Lows: two are by design (permissioned deployment, caret pragma), one is environment-dependent (PUSH0 / EVM
target), one is a benign OZ pattern (`_grantRole` return), and the one finding new to this release — Empty Block —
is the deliberate idiom of the authorization-hook pattern introduced in v0.5.0, where the access check lives on
the modifier and the override body is empty on purpose.
