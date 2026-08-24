# CMTAT Factory — Code Quality Review (v0.5.0)

| | |
| --- | --- |
| **Scope** | `contracts/` — `standard/`, `light/`, `libraries/`, `mocks/` (1101 lines of Solidity). Excludes `node_modules` (OpenZeppelin) and the vendored `CMTAT/` submodule. |
| **Commit** | `3492153` (branch `style`), plus the uncommitted v0.5.0 release changes |
| **Factory version** | `0.5.0` |
| **Compiler** | solc `0.8.36`, optimizer on (200 runs), EVM `prague`, Hardhat `2.26.3` |
| **Dependencies** | CMTAT `v3.3.0-rc3`, OpenZeppelin Contracts (+ Upgradeable) `5.7.0` |
| **Date** | 2026/08/24 |
| **Produced with** | Claude Code (Opus 5) |

> **This is a code-quality review, not a security audit.** Nothing in this report is a vulnerability.
> No finding below lets an unauthorized party move value, bypass a restriction, deploy without
> `CMTAT_DEPLOYER_ROLE`, or brick a factory. The findings are about legibility, duplication,
> extensibility, documentation accuracy, and one measured 114-gas saving.
>
> For the security posture of this release see [`AUDIT_OVERVIEW.md`](../AUDIT_OVERVIEW.md) and the
> Slither / Aderyn / Nethermind AuditAgent runs under `doc/audits/`.

## Disposition summary

| ID | Finding | Outcome | Where |
| --- | --- | --- | --- |
| A-1 | No loops anywhere in the factories | ⬜ nothing to do | — |
| B-1 | `cmtatCounterId` read twice in `_deployAndRegisterProxy` | ✅ fixed (114 gas measured) | `CMTATFactoryRoot.sol:129` |
| B-2 | `unchecked` on the counter increment | ⬜ declined (68 gas) | `CMTATFactoryRoot.sol:133` |
| C-1 | `CMTATDeployed` has exactly one emit site | ⬜ keep — structurally enforced | `CMTATFactoryRoot.sol:132` |
| C-2 | Constructor configuration emits no event | ⬜ keep — all immutable, no setter exists | `CMTATFactoryRoot.sol:41` |
| D-0 | Cost of a shared-parent member to a child that never calls it | ⚠️ measured — `internal` 0 bytes, `public` +79 and +1 ABI entry | probes |
| D-1 | `_initializerData` byte-identical in two pairs of factories | ⚠️ **revised** — leave; must not hoist into `CMTATFactoryRoot` | 4 factories |
| D-2 | `Create2.computeAddress(...)` written identically 3× | ⬜ decide — placement checked, clean | 3 files |
| E-1 | 13/13 public functions `virtual`, only 2/18 internal ones | ⚠️ open — highest-value finding | all libraries |
| F-1 | ERC-8303 / ERC-165 interface id and dispatch | ⬜ correct as written | `ContractVersion.sol` |
| G-1 | Agent-guide file tree omits 3 of 7 `libraries/` files | ✅ fixed | `CLAUDE.md` / `AGENTS.md` |
| G-2 | "all three factories" / "three factory families" — there are 5 and 4 | ✅ fixed | `CLAUDE.md` / `AGENTS.md` |
| G-3 | `VERSION` attributed to `CMTATFactoryRoot`, lives in `ContractVersion` | ✅ fixed | `CLAUDE.md` / `AGENTS.md` |
| G-4 | Root README API sketch: wrong visibility and return type | ✅ fixed | `README.md` |
| G-5 | NatSpec block-length distribution | ⬜ healthy — no action | — |
| H-1 | `computedProxyAddress` answers for a consumed one-shot salt | ⚠️ open — fix proposed, not applied | `CMTATFactoryRoot.sol:34` |
| H-2 | Beacon factory fails open on a zero implementation | ⬜ keep — documented and deliberate | `CMTAT_BEACON_FACTORY.sol:28` |
| I-1 | `beacon` typed as `UpgradeableBeacon`, factory calls one member | ⬜ keep — reasoned below | `CMTATBeaconFactoryBase.sol:17` |
| I-2 | Full CMTAT implementation imported for a 4-byte selector | ⬜ **keep** — measured, costs 0 bytes | 5 factories |
| J-1 | `libraries/` holds 5 abstract contracts, 1 interface, 1 library | ⬜ decide — naming | `contracts/libraries/` |
| J-2 | Downstream probe: enumerable-roles factory | ⬜ inconvenience only, not a blocker | probe compiled |

**Counts:** 22 rows — 5 fixed, 3 open/revised, 14 deliberately left (of which 4 are "checked, nothing wrong").
D-1 and D-2 were **revised after review feedback**; see the note at the head of section D.

## Outstanding

| ID | Item | Why it is still open |
| --- | --- | --- |
| E-1 | `virtual` on internal functions | Touches 16 signatures across 3 files. Behaviour-free, but it is an API-surface decision (what the project promises subclasses it can override) and should be the maintainer's call, not a reviewer's. |
| H-1 | No way to ask whether a custom salt is still available | The fix is additive (one public view). Left unapplied because it adds to the public ABI, which belongs in a release decision. |
| D-1 | `_initializerData` duplication | **Revised to leave.** The only shared ancestor of each pair is `CMTATFactoryRoot`, which the Light factories also inherit — hoisting there would couple the Light variants to `CMTATStandardUpgradeable` at compile time. A pair-level mixin would respect the constraint but costs two files to save 18 lines. |
| D-2, J-1 | Address-computation duplication; directory naming | Genuine judgement calls, not defects. D-2's placement was re-checked and is clean. |

---

## A. Loops and iteration

### A-1. There are none — and that is the finding

`grep -rn "for *(\|while *(" contracts/` returns **nothing**. The factories contain no iteration at
any visibility, so the whole category — increment form, hoisting, unbounded caller-controlled loops —
is vacuous here.

Worth stating explicitly because it is the usual first stop in a gas review, and because it means
`cmtatsList` is only ever appended to and indexed, never scanned. The one array in the codebase
cannot grow into a gas problem for the contract itself.

On `memory` vs `calldata`: the five public `deployCMTAT` entrypoints already take
`CMTAT_ARGUMENT calldata` / `CMTAT_LIGHT_ARGUMENT calldata`. The `bytes memory` parameters
(`_getBeaconProxyBytecode`, `_deployAndRegisterProxy`, …) are all `internal`, where `calldata` is not
available. Nothing to change.

**Verdict: no action.**

## B. Storage reads

### B-1. `cmtatCounterId` is loaded twice in the deployment funnel — ✅ fixed

`contracts/libraries/CMTATFactoryRoot.sol:129`, before:

```solidity
cmtatAddress = Create2.deploy(0, deploymentSalt, bytecode);
emit CMTATDeployed(cmtatAddress, msg.sender, cmtatCounterId, deploymentSalt);  // SLOAD
++cmtatCounterId;                                                              // SLOAD + SSTORE
cmtatsList.push(cmtatAddress);
```

The emit loads the slot, then `++` loads it again. I expected the optimizer to forward the first load
to the second — nothing intervenes between them — which per the check-B caveat would have made
hand-caching a *pessimisation*. **It does not forward**, and the measurement is what settled it.

After:

```solidity
uint256 id = cmtatCounterId;
emit CMTATDeployed(cmtatAddress, msg.sender, id, deploymentSalt);
cmtatCounterId = id + 1;
```

**Measured**, by toggling the change in place and re-running one harness (`deployCMTAT` on
`CMTAT_UUPS_FACTORY`, counter-salt mode, after an identical warm-up deployment; three consecutive
transactions, gas identical to the unit each time):

| Variant | `gasUsed` | Δ |
| --- | --- | --- |
| Baseline (`++cmtatCounterId`) | 502,922 | — |
| **Cached local (applied)** | **502,808** | **−114** |
| Cached + `unchecked` (B-2) | 502,740 | −182 |

**Be honest about the size of this:** 114 gas on a 502,922-gas transaction is **0.023%**. The reason
to take it is that it costs nothing — one local variable, same line count, same clarity — not that it
matters to anyone's bill. The benchmark file was deleted; all 42 tests pass with the change.

**Verdict: implemented.**

### B-2. `unchecked` on the increment — ⬜ declined

`unchecked { cmtatCounterId = id + 1; }` saves a further **68 gas** (measured above). Overflow is
unreachable — it would take 2^256 deployments — so it is *safe*. It is declined anyway: it puts an
`unchecked` block, which every reader must stop and verify, into the single most security-sensitive
function in the codebase (the one the NM-2 reentrancy analysis is about), to save 0.013%. Note this
is **not** the check-A `unchecked { ++i }` anti-pattern — that one is elided automatically since
0.8.22 and buys literally zero; this one is real, just not worth it.

**Verdict: leave. Recorded so it is not re-opened.**

### B-3. Reads separated by the CREATE2 — checked, not actionable

In counter mode `cmtatCounterId` is also read by `nextDeploymentSalt()` *before* `Create2.deploy`, and
again after it in `_deployAndRegisterProxy`. This is the case the check-B caveat says does pay off,
because the optimizer cannot forward a load across the `create2` opcode. Threading the value through
would mean changing `_checkAndDetermineDeploymentSalt`'s signature across all five factories to save
one warm SLOAD. Not worth the API churn; recorded so the next reviewer does not re-derive it.

## C. Events

### C-1. One event, one emit site — ⬜ keep, and this is the good outcome

```
$ grep -rn "emit " contracts/ --include=*.sol   # excluding mocks
contracts/libraries/CMTATFactoryRoot.sol:132:  emit CMTATDeployed(...)
```

**One** emit site for **one** event, and every one of the five factories reaches it through
`_deployAndRegisterProxy`. "Every deployment emits" is therefore enforced *structurally* by the
funnel, not by convention — the exact property check C asks you to look for and which most codebases
fail. A sixth factory physically cannot register a deployment without emitting.

`indexed` placement is also right: `proxy`, `deployer` and `id` are indexed (the three a consumer
filters by) and `salt` is the data field. Three is the maximum for a non-anonymous event, so `salt`
could not have been indexed too — and it is the least useful of the four to filter on, since in
counter mode it is derivable from `id`.

**Verdict: keep. No change.**

### C-2. Constructor configuration emits nothing — ⬜ keep

`useCustomSalt`, `logic` and `beacon` are all set in constructors with no event. This is the headline
check-C smell, and here it does **not** apply: all three are `immutable`, there is no setter anywhere
in the codebase, and each has a public getter. There is no "silent write path" to guard, because
there is only ever one write and it is in the creation transaction. Adding a constructor event would
create exactly the C-1 problem this codebase currently does not have.

Role grants in the constructor (`_grantRole`) already emit OpenZeppelin's `RoleGranted`.

**Verdict: keep. No change.**

## D. Duplication

Both duplication findings below are real, measured in **code lines excluding NatSpec**, and both come
with a counter-argument. Neither is implemented: D-1 ends in *leave*, D-2 in *decide*.

> **Revised after review feedback.** The first version of this section proposed hoisting shared
> helpers without asking *which deployed contracts would then carry them*. A reviewer raised the
> constraint directly: an extraction must not push code into a deployment that does not use the
> function — UUPS being the obvious case, since it shares `CMTATFactoryBase` with Transparent but
> needs a different initializer selector. That constraint is correct and it changes the D-1
> recommendation. D-0 below measures exactly where it bites, because the answer is not the same for
> `internal` and `public` members.

### D-0. Where an extraction may land — measured

Before recommending any hoist, I measured what a shared-parent member actually costs a child that
never calls it. Two probes against `CMTATFactoryBase` (the parent of **UUPS** and Transparent), with
Transparent calling the hoisted member and UUPS not, comparing exact `deployedBytecode` lengths from
the artifacts rather than the size plugin's rounded KB:

| Probe placed in `CMTATFactoryBase` | `CMTAT_UUPS_FACTORY` deployed | Δ | UUPS ABI functions |
| --- | --- | --- | --- |
| baseline (no probe) | 4583 bytes | — | 18 |
| **`internal`** helper, called by TP, never by UUPS | **4583 bytes** | **0** | 18 |
| **`public`** helper, never called by UUPS | **4662 bytes** | **+79** | **19** — `probePublicHelper` now callable on UUPS |

**So the rule has two halves, and only one of them is about bytecode:**

- **`internal` members are stripped.** solc removes an inherited internal function no reachable path
  calls, so a child pays **exactly zero bytes** for a sibling's helper. Hoisting `internal` code into
  a shared parent has no deployment cost for the contracts that ignore it.
- **`public` members are not.** They land in every child's dispatch table *and its ABI* — UUPS gained
  a function it has no business exposing, and 79 bytes. This is the case the project's own
  "Refactoring safely" concern is about, and it is a real defect, not a size quibble: it widens the
  callable surface of a deployed contract for a helper it does not use.

The constraint therefore stands for anything `public`, and for `internal` it survives in a different
currency: **compile-time coupling and legibility**, not bytes. That second form is what disqualifies
the D-1 hoist below, so it is not a technicality.

**Method note:** the size plugin reports KB to three decimals (~1 byte of resolution), which is why
these numbers come from `deployedBytecode.length` in the build artifacts instead.

### D-1. `_initializerData` is byte-identical across two pairs of factories

Comparing comment-stripped bodies:

| Pair | Identical? | Code lines each |
| --- | --- | --- |
| `CMTAT_TP_FACTORY` vs `CMTAT_BEACON_FACTORY` | **yes, byte-for-byte** | 10 |
| `CMTAT_LIGHT_TP_FACTORY` vs `CMTAT_LIGHT_BEACON_FACTORY` | **yes, byte-for-byte** | 8 |

Both standard factories encode `CMTATStandardUpgradeable.initialize.selector` with the same four
fields; both Light factories encode `CMTATUpgradeableLight.initialize.selector` with the same two.
The proxy pattern differs between the members of each pair, but the initializer payload does not —
that is a function of the *implementation*, not the proxy.

**Where it could go is the deciding question, and it rules out the obvious answer.** The two members
of each pair are *not* siblings in the inheritance tree: `CMTATTransparentFactoryBase` and
`CMTATBeaconFactoryBase` share no ancestor below **`CMTATFactoryRoot`**, which all five factories
inherit. So "hoist it to the shared parent" means putting the **standard**-CMTAT encoder into the
contract the two **Light** factories also derive from.

Per D-0 that costs the Light factories **zero bytes** — the helper is `internal` and solc strips it.
But the coupling it creates is the real objection, and it is worse here than in the generic case: the
Light factories exist *specifically to avoid* `CMTATStandardUpgradeable`, and routing their common
ancestor through an import of it would make the lightweight variants compile-time dependent on the
heavyweight implementation they were built to escape. That is a genuine regression in the thing the
Light factories are for, even at 0 bytes. It would also be invisible in a size report, which is
exactly why it is worth writing down.

Two further arguments against, both surviving the measurement:

- The encoding must stay in lockstep with `computedProxyAddress`, because the initializer bytes feed
  the CREATE2 `init_code` hash — the project's own guide says so ("If you modify proxy creation
  bytecode, re-check both deployment and `computedProxyAddress(...)`"). Keeping the encoder next to
  the factory that uses it keeps that review local.
- The total prize is ~18 code lines.

**Revised verdict: leave — and if it is ever extracted, not into `CMTATFactoryRoot`.** The only
placement that respects the constraint is a pair-level mixin outside the Root chain —
`CMTATStandardInitializer` inherited by `CMTAT_TP_FACTORY` + `CMTAT_BEACON_FACTORY` only, and
`CMTATLightInitializer` by the two Light factories only — so each encoder reaches exactly the two
deployments that call it and no others. That costs two new files and a second inheritance edge to
save 18 lines, which is why the recommendation is still *leave*; the placement is recorded so that a
future extraction does not take the tempting shortcut through Root.

### D-2. The CREATE2 address computation is written three times

Identical line in three files:

```
CMTATBeaconFactoryBase.sol:84       return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
CMTATTransparentFactoryBase.sol:65  return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
CMTAT_UUPS_FACTORY.sol:67           return Create2.computeAddress(effectiveDeploymentSalt,  keccak256(bytecode), address(this) );
```

The same three-times duplication exists for the deploy wrapper
(`_deployAndRegisterProxy(bytecode, deploymentSalt)` then cast to the proxy type, in the same three
files). Unlike D-1 there is **no** constraint preventing extraction here — no per-contract custom
error is named, no storage is touched, and `CMTATFactoryRoot` is already the shared parent that owns
`_deployAndRegisterProxy`. A one-line `_computeProxyAddress(bytes memory bytecode, bytes32 salt)`
`internal view` in `CMTATFactoryRoot` would be inherited by all three call sites unchanged.

Note the structural asymmetry this exposes: Transparent and Beacon each have a `…FactoryBase` mixin,
but **UUPS has none** — `CMTAT_UUPS_FACTORY` inlines `_deployBytecode` and `_getBytecode` that its
siblings inherit. A reader looking for "where does UUPS do this" has to learn that the answer is
"nowhere, it is in the concrete factory".

**Checked against the D-0 constraint, and this one passes.** The natural home is
`CMTATFactoryRoot`, which all five factories inherit — so the question is whether any of them would
be carrying code it does not use. None would: every one of the five computes a proxy address.

```
CMTAT_TP_FACTORY.sol:62          -> _computedTransparentProxyAddress(...)
CMTAT_LIGHT_TP_FACTORY.sol:52    -> _computedTransparentProxyAddress(...)
CMTAT_BEACON_FACTORY.sol:69      -> _computedBeaconProxyAddress(...)
CMTAT_LIGHT_BEACON_FACTORY.sol:57 -> _computedBeaconProxyAddress(...)
CMTAT_UUPS_FACTORY.sol:67        -> Create2.computeAddress(...) inline
```

The helper would be `internal` (so zero bytes even for a hypothetical non-user) and, unlike D-1, it
introduces **no new import** — `CMTATFactoryRoot` already imports `Create2` for `Create2.deploy`. The
extraction adds nothing to any deployment that would not otherwise use it.

The deploy-wrapper duplication in the same three files is a different case and must **not** be
merged: `_deployBeaconProxyBytecode`, `_deployTransparentProxyBytecode` and `_deployBytecode` differ
in return type (`BeaconProxy` / `TransparentUpgradeableProxy` / `ERC1967Proxy`). Their shared core is
already `_deployAndRegisterProxy` in `CMTATFactoryRoot`; what remains per-file is the typed cast,
which is exactly the part that cannot be shared.

**Verdict: decide — and unlike D-1 this one is clean.** The extraction is safe, small, adds no
dependency, and lands only where it is used; the UUPS-has-no-base asymmetry is the stronger argument
for doing it.

## E. `virtual` / override convention

### E-1. Public surface is 100% `virtual`; the internal surface is 11% — ⚠️ open

Full scan of `contracts/` (mocks excluded):

| Visibility | `virtual` | total | |
| --- | --- | --- | --- |
| `public` / `external` | **13** | 13 | 100% |
| `internal` | **2** | 18 | **11%** |

The convention is not something this review is imposing — it is the project's own, and the evidence
is that the codebase contradicts itself **inside a single file**. In `CMTATFactoryRoot.sol`:

```solidity
function _checkAndDetermineDeploymentSalt(bytes32) internal virtual returns (bytes32)  // L105  virtual
function _deployAndRegisterProxy(bytes memory, bytes32) internal returns (address)     // L129  NOT virtual
function _computeDeploymentSalt(bytes32) internal view virtual returns (bytes32)       // L142  virtual
```

Three sibling internal functions, in sequence, and the middle one differs. Whichever answer is right,
they cannot all be right as written. Corroborating evidence from the ecosystem the project vendors:
in `CMTAT/contracts/modules/`, **118 of 129** internal functions (~91%) are `virtual`.

**Prioritised by consequence, not by count:**

| Function | File | Why it matters |
| --- | --- | --- |
| `_deployAndRegisterProxy` | `CMTATFactoryRoot.sol:129` | **Highest.** The single funnel every deployment passes through. A subclass wanting extra per-deployment bookkeeping — a secondary index, a per-deployer counter, a hook — cannot reach it. Its two neighbours are both overridable. |
| `_checkProxyAdminOwner` | `CMTATTransparentFactoryBase.sol:91` | A validation hook. A subclass cannot tighten it (e.g. require the owner to be a known multisig) or relax it. |
| `_getTransparentProxyBytecode` / `_getBeaconProxyBytecode` | both bases | Cannot swap the proxy contract without forking the base. |
| the 12 remaining `_deploy*` / `_computed*` / `_initializerData` | all libraries | Lower value individually, but they are what makes the inconsistency visible. |

`virtual` on an internal function is resolved statically and is free at runtime. I did **not** run a
gas benchmark for this, because the change was not applied — stated here rather than implied.

**Verdict: open.** Recommended: add `virtual` to all 16, restoring one rule. Left to the maintainer
because it widens what the project promises subclasses can override, and that promise is a release
decision. If the answer is instead "internal functions are deliberately final", then the two `virtual`
keywords in `CMTATFactoryRoot` should come off — either way, the file should stop contradicting itself.

**Test guard if implemented:** a subclass in `contracts/mocks/` that overrides
`_deployAndRegisterProxy` and asserts the override is *reached* (not merely that it compiles — a
compile-only harness will not catch a silently shadowed override).

## F. ERC / specification conformance

### F-1. ERC-8303 and ERC-165 — ⬜ correct as written

The factories claim exactly one ERC beyond OpenZeppelin's: **ERC-8303** (`version()`), via
`ContractVersion`. Checked:

- **Interface id.** The classic ERC-165 bug is `type(IFoo).interfaceId` covering only directly
  declared selectors. `IERC8303` **inherits nothing** and declares exactly one function, so its id is
  simply `version()`'s selector. Safe as written, and no flattened-id helper is needed.
- **Dispatch.** `ContractVersion.supportsInterface` returns `true` for `type(IERC8303).interfaceId ||
  super`; `CMTATFactoryRoot` overrides `override(AccessControl, ContractVersion)` and defers to
  `super`, so the C3 chain reaches both branches. `test/ContractVersion.test.js` already asserts this
  across all five factories, including the inherited `AccessControl` and `ERC165` ids.
- **Semantics, not just shape.** `version()` returns a version string that tracks the release; it is
  not a stub.
- **Sentinels.** `address(0)` is rejected for `factoryAdmin`, `logic` and `proxyAdminOwner`. The one
  place it is *accepted* is the beacon implementation — see H-2, which is deliberate.

**Verdict: no change.**

## G. Code / documentation mismatch

### G-5. NatSpec block lengths are healthy — ⬜ no action (reported first, because it changes how you read the rest)

Measured across `contracts/` excluding mocks — **74 blocks**:

| median | p90 | max |
| --- | --- | --- |
| **5 lines** | 10 | **15** |

The four longest blocks are 13–15 lines, all on `deployCMTAT` / the beacon constructor, and all
consist of `@notice` + a short `@dev` list + one `@param` per argument + `@return`. There is no long
tail: no 24–44 line contract header of the kind check G warns about, and a reader opening any file
reaches code immediately. Grepping the contracts for `.md`, `doc/` and `See <file>` returns **nothing**
— no NatSpec delegates its substance to a documentation file that a block-explorer reader would not
have.

This is the state check G is aiming at, so it is worth recording rather than passing over silently.

### G-1 … G-4. Four claims that were wrong — ✅ all fixed

Found by grepping the docs for claims and testing each against the code, rather than reading code and
hoping to recall a contradiction.

| ID | Claim | Reality | Fix |
| --- | --- | --- | --- |
| **G-1** | `CLAUDE.md` / `AGENTS.md` "Project Structure" lists `libraries/` as 4 files | It holds **7**: `CMTATTransparentFactoryBase.sol`, `CMTATBeaconFactoryBase.sol` and `ContractVersion.sol` were missing — including both proxy-pattern base contracts, which is most of the shared logic | tree completed, ordered base→derived |
| **G-2** | "For all **three** factories, deployment follows…" and "update tests across all **three** factory families" | **Five** factories since v0.3.0; **four** test families (`UUPS/`, `Transparent/`, `beacon/`, `Light/`) | corrected to five and four, with the directories named |
| **G-3** | Architecture sketch puts `VERSION = "0.5.0"` under `CMTATFactoryRoot` | `VERSION` is a private constant of **`ContractVersion`**, exposed via `version()`; `CMTATFactoryRoot` merely inherits it | `ContractVersion` given its own node; `CMTATFactoryRoot`'s bases listed accurately |
| **G-4** | Root README API sketch declares every entrypoint `external` and `deployCMTAT` as `returns (address)` | All six are **`public`**; `deployCMTAT` returns the **concrete proxy type** (`ERC1967Proxy`, `TransparentUpgradeableProxy`, `BeaconProxy`) | corrected, with a comment naming the three return types |

**G-4 is mine.** That sketch was written during the README split earlier in this session and was wrong
when written — an integrator copying it into an interface would get a signature that does not match
the deployed ABI. Recorded rather than quietly corrected, per the "correct yourself in place" rule.

In every case the **code was right and the documentation was the defect**; no contract was changed for
G.

## H. Weird behaviour — correct, but at odds with the purpose

### H-1. The address predictor keeps answering for a salt that can never be used again — ⚠️ open

A custom salt is one-time-use: `_checkAndDetermineDeploymentSalt` records it in `customSaltUsed` and
a second `deployCMTAT` with it reverts `CMTAT_Factory_SaltAlreadyUsed`. But `computedProxyAddress`
and `computedNextProxyAddress` **never consult that mapping**. Verified by running it, not by reading:

```
predicted before: 0xF1dc6b7d9414142736ba6043D179cb441736811B
deployCMTAT(salt) -> ok
deployCMTAT(salt) -> reverts CMTAT_Factory_SaltAlreadyUsed
predicted after : 0xF1dc6b7d9414142736ba6043D179cb441736811B   <- unchanged, no signal
```

The predictor returns a counterfactual address that is no longer reachable, and returns it with the
same confidence as a live one. This is the check-H shape exactly: *correct* — CREATE2 really would
put a contract there — but at odds with what the function is for, which is telling an integrator
where their next token will land.

It compounds because **`customSaltUsed` is `internal`** (`CMTATFactoryRoot.sol:34`) with no public
getter. An integrator has no on-chain way to ask "is this salt still available?" short of reading the
raw storage slot or sending a transaction and watching it revert.

**Not a vulnerability:** the deployment itself still reverts correctly, so nothing is deployed twice
and no address is stolen. The cost is a wasted transaction and a misleading pre-flight check.

**Proposed fix — additive, zero behaviour change:**

```solidity
/**
* @notice Whether a custom salt has already been consumed by a deployment.
* @param salt The custom salt to check.
* @return used True if a deployment already used this salt, so deployCMTAT would revert.
*/
function isCustomSaltUsed(bytes32 salt) public view virtual returns (bool used) {
    return customSaltUsed[salt];
}
```

Deliberately *not* making `computedProxyAddress` revert on a consumed salt: a pure predictor that
sometimes reverts is harder to compose, and `computedNextProxyAddress` would inherit the behaviour.

**Verdict: open** — the fix adds to the public ABI, which belongs in a release decision.

### H-2. The beacon factory fails open where its siblings fail closed — ⬜ keep

`CMTAT_BEACON_FACTORY.sol:28`:

```solidity
implementation_ == address(0) ? address(new CMTATStandardUpgradeable(address(0))) : implementation_
```

The UUPS and Transparent factories **revert** on a zero `logic_`
(`CMTAT_Factory_AddressZeroNotAllowedForLogicContract`). The two beacon factories instead treat zero
as "deploy me a fresh implementation". Same sentinel, opposite policies, in one contract family — and
a mistyped constructor argument silently produces a working-but-unintended factory rather than a
revert.

Checked before reporting: this is **documented and deliberate** — it is invariant 3 in the project's
own guide ("Beacon factory tolerates `implementation_ == address(0)` by deploying a fallback"), it is
in the `@dev` block on the constructor, and `test/beacon/` covers it
(`testCanDeployFactoryWithNoImplementation`). It is also genuinely useful: the beacon owns the
implementation pointer, so a beacon factory is the one variant that can meaningfully bootstrap its
own implementation.

**Verdict: keep.** Recorded here so a future reviewer meeting the asymmetry finds the reasoning
instead of re-opening it. It is worth noting the cost in the docs, though: `CMTAT_BEACON_FACTORY`'s
init code is **29.792 KB** against 7.640 KB for `CMTAT_TP_FACTORY`, because the fallback branch drags
the entire CMTAT creation code into the factory's own deployment.

### H-3. Dead-ish behaviour checked, nothing found

- `CMTATProxyAddress` returns `address(0)` for an unknown id rather than reverting — documented in its
  own `@dev`, tested, and the right choice for a getter that indexers poll.
- `_computedTransparentProxyAddress` calls `_checkProxyAdminOwner`, so the *view* reverts on a zero
  owner exactly where the deploy would. Redundant work that buys a better error message — check H says
  keep it, and it is also what keeps prediction and deployment in agreement.
- `nextDeploymentSalt()` returns a counter-derived salt that is never used when
  `useCustomSalt == true`. Its NatSpec says so in the first line. Leave.
- No branch was found that is unreachable because an earlier one returned.

## I. Interface granularity — requiring more than you call

### I-1. `beacon` is typed as the concrete `UpgradeableBeacon`; the factory calls one member — ⬜ keep

`CMTATBeaconFactoryBase.sol:17` stores `UpgradeableBeacon public immutable beacon`. Counting what the
factory actually calls on it: **`implementation()`, and nothing else.** `UpgradeableBeacon` also
carries `upgradeTo`, `owner`, `transferOwnership`, `renounceOwnership`. On the letter of check I that
is a strict subset, and `IBeacon` (one function) would be the minimal type.

**It should stay as it is**, for a reason specific to this design: the factory *constructs* the beacon
(`new UpgradeableBeacon(...)`), so it needs the concrete type regardless — narrowing the field to
`IBeacon` would not remove the dependency, only hide it from the getter. And the public
`beacon()` getter is the documented way `beaconOwner` reaches `upgradeTo` to migrate every deployed
token. Narrowing the type would make the *most important operation in the beacon pattern* harder to
reach, to satisfy a rule aimed at a different problem (rejecting valid implementations, which cannot
happen here — the factory creates the only beacon it ever uses).

**Verdict: keep. Do not narrow.**

### I-2. Importing the whole CMTAT implementation to read a 4-byte selector — ⬜ **keep** (measured; my initial reading was wrong)

All five factories do a version of:

```solidity
import {CMTATStandardUpgradeable} from "../../CMTAT/contracts/deployment/CMTATStandardUpgradeable.sol";
...
abi.encodeWithSelector(CMTATStandardUpgradeable(address(0)).initialize.selector, ...)
```

`CMTATStandardUpgradeable` is a full 15-module token pulled in, for the Transparent and UUPS
factories, purely to name one constant. That reads like the textbook check-I finding, and I expected
it to cost deployed bytecode.

**It does not.** I replaced the import in the real `CMTAT_TP_FACTORY` with a minimal local interface
declaring only `initialize(...)`, rebuilt with `--force`, and compared:

| `CMTAT_TP_FACTORY` | deployed | init code |
| --- | --- | --- |
| concrete import (current) | 7.075 KB | 7.640 KB |
| minimal interface (probe) | **7.075 KB** | **7.640 KB** |

Identical. The selector is a compile-time constant and the creation code is never referenced, so solc
emits nothing extra. The probe's interface produced the same selector (`0x5a54663c`) and all 7
Transparent tests passed against it.

**So the concrete import costs nothing — and it buys something real.** If CMTAT ever changes
`initialize`'s signature, the current import **fails to compile**, loudly, at the point of change. A
hand-maintained minimal interface would keep compiling and silently produce a *wrong selector*,
deploying proxies whose initializer call reverts — a failure that surfaces only in production. Given
the vendored submodule is a release candidate (`v3.3.0-rc3`) still moving between versions, the loud
failure is worth more than the tidiness.

The residual cost is compile-time coupling: `CMTATFactoryRoot` cannot compile without the CMTAT
submodule, because `CMTATFactoryInvariant` imports `ICMTATConstructor`. That is inherent to a factory
whose purpose is deploying CMTAT, not an accident of this import.

**Verdict: keep. Recorded explicitly so it is not "cleaned up" later** — the probe and its measurement
are the argument.

## J. Modularity

### J-1. `contracts/libraries/` contains one library — ⬜ decide

Checking directory names against contents:

| File in `libraries/` | Actually declares |
| --- | --- |
| `CMTATBeaconFactoryBase.sol` | `abstract contract` |
| `CMTATFactoryBase.sol` | `abstract contract` |
| `CMTATFactoryInvariant.sol` | `abstract contract` |
| `CMTATFactoryRoot.sol` | `abstract contract` |
| `CMTATTransparentFactoryBase.sol` | `abstract contract` |
| `ContractVersion.sol` | `interface` + `abstract contract` |
| `FactoryErrors.sol` | **`library`** |

One library out of seven files. Check J calls out "a `libraries/` directory holding no `library`" —
this is the near-miss version, and the effect on a reader is the same: the directory groups by
*nothing in particular*, and someone asking "where does the salt logic live?" is not helped by
"libraries".

The ecosystem convention is available and costs nothing to follow: upstream CMTAT uses
`contracts/modules/` for abstract mixins, `contracts/interfaces/` for interfaces, and
`contracts/libraries/` for actual libraries. Adopting it would mean `base/` (or `modules/`) for the
five abstract contracts, `interfaces/` for `IERC8303`, and `libraries/` for `FactoryErrors` alone.

**Counter-argument:** it is a pure rename touching every import path in the project, for a
seven-file directory, on a codebase this small.

**Verdict: decide.** Following the sibling project's convention is the stronger argument, but the
churn is real and this is not a defect.

### J-2. Downstream probe: a factory that wants enumerable roles — ⬜ inconvenience, not a blocker

Rather than assert modularity by reading, I picked the most plausible downstream project — someone
building a CMTAT factory who wants `AccessControlEnumerable` so roles can be listed on-chain — wrote
it, and compiled it.

**Probe, first attempt:**

```solidity
contract ProbeEnumerable is AccessControlEnumerable, CMTATFactoryRoot {
    constructor(address a) CMTATFactoryRoot(a, false) {}
}
```

```
TypeError: Derived contract must override function "_grantRole".      (6480)
TypeError: Derived contract must override function "_revokeRole".     (6480)
TypeError: Derived contract must override function "supportsInterface". (6480)
Error HH600: Compilation failed
```

**Graded: `Error (6480)` only — the inconvenience tier, not the blocker tier.** No `Error (5005)`
"linearization impossible", and no same-signature-different-return-type collision. Adding the three
standard overrides compiles cleanly (2.537 KB deployed), which I verified rather than assumed.

That is a genuinely good result and the reason is worth naming: `CMTATFactoryRoot` inherits
`AccessControl` — OpenZeppelin's base — rather than some project-specific access module, so a
downstream contract that also derives from `AccessControl` shares a base instead of fighting one.
The three overrides are the same boilerplate any OZ user writes when combining extensions.

Two smaller check-J observations, neither currently breaking anything:

- **`ContractVersion` is a version mixin sitting in the reusable layer**, and check J flags exactly
  that: `version()` belongs to the deployable contract, not the shared base. A downstream factory
  inheriting `CMTATFactoryRoot` reports CMTA's `"0.5.0"` by default. Mitigated in practice —
  `version()` is `public virtual`, so it *can* be overridden — but the default is someone else's
  release number.
- **No interface for the project's own API.** There is no `ICMTATFactory` declaring
  `deployCMTAT` / `computedProxyAddress` / `CMTATProxyAddress` / `nextDeploymentSalt`, so an
  integrator wanting to call a factory must import the concrete contract and its whole dependency
  graph — including the CMTAT submodule (see I-2). For a project whose entire purpose is being called
  by other systems, that is the modularity gap most likely to be felt. Worth considering for a future
  release; not a defect today, since there is one implementation family and it is in this repo.

**Verdict: no blocker found. The probe files were deleted after measurement.**

---

## What was changed by this review

| File | Change |
| --- | --- |
| `contracts/libraries/CMTATFactoryRoot.sol` | B-1: cache `cmtatCounterId` in the deployment funnel (−114 gas, measured) |
| `CLAUDE.md`, `AGENTS.md` | G-1, G-2, G-3: complete the `libraries/` file tree, correct "three factories"→five and "three test families"→four, attribute `VERSION` to `ContractVersion` |
| `README.md` | G-4: correct the API sketch's visibility (`external`→`public`) and `deployCMTAT` return type |

Section D was **revised after review feedback** (see the note at its head): an extraction must not
push code into a deployment that does not use it. D-0 measures that cost, D-1's verdict changed from
"decide" to "leave, and not into `CMTATFactoryRoot`", and D-2's placement was re-checked and found
clean. No contract changed as a result — the revision is to the recommendations.

No contract behaviour changed. All **42 tests pass**; the style checker (`check_order.py`) reports
**0 violations** across all 8 checks; `npm run check:oz` exits 0.

Temporary artifacts created for measurement — the gas harness, the H-1 probe test and both modularity
probes under `contracts/probe/` — were **deleted**; the test count is unchanged at 42, which is the
check that nothing was left behind.

---

**Commit message**

```
docs(audits): add v0.5.0 code-quality review; cache deployment counter and fix doc mismatches
```
