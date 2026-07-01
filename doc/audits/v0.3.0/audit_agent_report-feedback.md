# AuditAgent report feedback — v0.3.0

- **Tool:** Nethermind **AuditAgent** (AI-generated automated scan — see the report's own *Important Notice*: "generated entirely by AI… not a full security audit… must be independently verified").
- **Report:** `audit_agent_report_v0.3.0.pdf` (Scan ID 6, June 30 2026).
- **Target:** branch `main`, commit `18a8e66c…07016ec8`, 12 factory contracts (868 LoC).
- **Result reported:** 2 findings — 0 High · 0 Medium · **1 Low** · **1 Info** · 0 Best-practice.
- **Branch triaged on:** `dev`. No fix commits land for these (see disposition); both are accepted-as-design.

## Outcome

**Nothing to fix (0 fixed / 2 accepted-as-design / 0 rejected).** Both findings describe the *same* intrinsic
property of the shared counter-derived CREATE2 salt (`keccak256(cmtatCounterId)`), seen from two angles
(cross-deployer front-running, and reentrant reuse). Both are real behaviors, neither is exploitable for fund loss
or state corruption, and the factory already ships the mechanism (custom-salt mode) that removes the cross-deployer
race for anyone who needs a reserved address. A small documentation clarification and an optional `nonReentrant`
hardening are noted below as improvements, not required fixes.

## Per-finding triage

| ID | Severity (tool → ours) | Disposition | Status / commit |
| --- | --- | --- | --- |
| NM-1 | Low → Low/Info | **Accepted as design** | No code change (docs clarification optional) |
| NM-2 | Info → Info | **Accepted as design** | No code change (`nonReentrant` hardening optional) |

---

### NM-1 — "Counter-derived next-address helpers are front-runnable across authorized deployers" (Low)

**Claim.** With `useCustomSalt == false`, both `computedNextProxyAddress(...)` and `deployCMTAT(...)` derive the
effective salt from the shared global `cmtatCounterId` (`nextDeploymentSalt() = keccak256(abi.encodePacked(cmtatCounterId))`,
`CMTATFactoryRoot.sol:72-74`). Caller-supplied `deploymentSaltInput` is ignored in that mode. So if Alice predicts
the "next" address and pre-funds it, another role-holder Bob can deploy first, advance the counter, and Alice's later
deploy lands at a different address — stranding whatever Alice pre-sent to the predicted address.

**Verdict: Accepted as design — no code change.**

- The behavior is real and correctly described. It is **intrinsic to a shared sequential-counter CREATE2 scheme**:
  in counter mode there is a single global salt sequence (`CMTATFactoryRoot.sol:85-96`), so "the next address" is a
  property of the *factory's* next deployment, not of a specific caller. `computedNextProxyAddress` is documented as
  exactly that — "the next proxy address using the same salt selection as `deployCMTAT`" (README L205) — i.e. valid
  only until the next deployment by anyone.
- **The factory already provides the mitigation: custom-salt mode (`useCustomSalt == true`).** There each caller
  supplies its own salt, reserved one-time-use via `customSaltUsed` (`CMTATFactoryRoot.sol:86-92`); reuse reverts with
  `CMTAT_Factory_SaltAlreadyUsed`. A specific predicted address can then be neither shifted nor stolen by another
  deployer. So the "predict-then-pre-fund a guaranteed address" workflow **is** supported — via custom salt — and the
  helper's caller chose the non-reserving mode.
- **Precondition is a trusted-role threat model.** It needs ≥2 holders of `CMTAT_DEPLOYER_ROLE`, at least one
  adversarial/negligent, and an admin that doesn't revoke. `CMTAT_DEPLOYER_ROLE` is admin-granted (`CMTATFactoryRoot.sol:33-34`),
  not permissionless — deployment is gated by `onlyRole(CMTAT_DEPLOYER_ROLE)` (`CMTAT_UUPS_FACTORY.sol:43`).
- **Impact is griefing of a convenience helper.** No factory-held funds are at risk and no on-chain state is corrupted;
  pre-funding a *non-reserved* predicted address is an off-chain decision. Low (arguably Informational for this repo's
  single-/coordinated-deployer model) is fair.

**Optional improvement (not a fix):** add a one-line natspec/README caveat on `computedNextProxyAddress` /
`nextDeploymentSalt` that, in counter mode, the prediction is only stable while no other deployment intervenes, and
that custom-salt mode should be used to reserve a specific address across multiple deployers.

---

### NM-2 — "Counter-derived salts can be reused during reentrant proxy initialization" (Info)

**Claim.** In `_deployAndRegisterProxy` (`CMTATFactoryRoot.sol:108-114`), `Create2.deploy` runs **before**
`++cmtatCounterId`. Proxy constructors (`ERC1967Proxy` / `TransparentUpgradeableProxy` / `BeaconProxy`) execute the
CMTAT initializer during construction. If that initializer path reenters `deployCMTAT` via a contract that also holds
`CMTAT_DEPLOYER_ROLE`, the reentrant call observes the same un-incremented `cmtatCounterId` and derives the **same**
automatic salt. Because the two init codes differ, the two CREATE2 addresses still differ, so both deploys succeed —
but one salt value is reused across two events and one counter-derived salt is skipped.

**Verdict: Accepted as design / informational — no required code change.**

- The mechanism is correctly identified (deploy-before-increment), but the path is **not reachable with the
  implementations these factories deploy.** Reentry requires the proxy's initializer to hand control to an
  attacker-controlled contract that calls back into `deployCMTAT`, *and* that contract must hold
  `CMTAT_DEPLOYER_ROLE`. The standard/light CMTAT `initialize` configures token state and stores engine addresses; it
  does not make an outbound call into an arbitrary external address during construction that could reenter. (Verify
  against the pinned CMTAT initializer before relying on this for any non-standard implementation passed as `logic_`.)
- **Even if reached, on-chain invariants hold.** Each deployment still gets a **unique CREATE2 address** (distinct
  init code ⇒ distinct address; `Create2.deploy` reverts on a genuine collision), a **unique sequential id**, and a
  **consistent `cmtatsList`** — index == id is preserved because the matching `++cmtatCounterId` and `cmtatsList.push`
  are paired within each call (`CMTATFactoryRoot.sol:111-113`). No fund loss, no registry corruption.
- The only anomaly is **off-chain bookkeeping**: two `CMTATDeployed` events could carry the same `salt` field and one
  counter-derived salt value is never used. That breaks the cosmetic "one-counter-one-salt" assumption for off-chain
  indexers, not any on-chain safety property. Informational is fair.

**Optional hardening (defense-in-depth, not required):** add OZ `ReentrancyGuard` and mark the public `deployCMTAT`
entrypoints `nonReentrant`. This is the clean option. Note a naive CEI reorder (moving `++cmtatCounterId` before
`Create2.deploy`) must still preserve `cmtatsList` index == id under reentrancy, so a `nonReentrant` guard is
preferred over reordering. If neither is adopted, this stays an accepted informational item — its safety rests on the
trusted, non-reentrant CMTAT initializers actually deployed.

---

## Notes on the report itself

- The report is explicitly AI-generated and self-flagged as "not a full security audit" requiring independent human
  verification — this file is that verification for the factory's own code.
- Both findings are scoped correctly to the factory contracts (no dependency/submodule noise, unlike the unfiltered
  Slither run). Neither overlaps the Aderyn H-1 false positive (CREATE2 init-code encoding) — see
  [aderyn-report-feedback.md](./aderyn-report-feedback.md).

## Executive triage

**Nothing to fix.** NM-1 and NM-2 are two views of the deliberate shared counter-derived salt design. NM-1's
cross-deployer race is removed by the already-shipped custom-salt mode for anyone needing a reserved address; NM-2's
reentrant reuse is unreachable with the trusted CMTAT initializers and, even hypothetically, only perturbs off-chain
event bookkeeping while every on-chain invariant (unique address, unique id, `cmtatsList` index == id) holds. Suggested
follow-ups are optional quality improvements: a one-line doc caveat on the prediction helpers (NM-1) and an optional
`nonReentrant` guard on `deployCMTAT` (NM-2).
