# CHANGELOG

Please follow <https://changelog.md/> conventions.

## Semantic Version 2.0.0



Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when the new version makes:
   - Incompatible proxy **storage** change internally or through the upgrade of an external library (OpenZeppelin)
   - A significant change in external APIs (public/external functions) or in the internal architecture
2. MINOR version when the new version adds functionality in a backward compatible manner
3. PATCH version when the new version makes backward compatible bug fixes

See [https://semver.org](https://semver.org/)

## Type of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

Reference: [keepachangelog.com/en/1.1.0/](https://keepachangelog.com/en/1.1.0/)

Custom changelog tag: `Dependencies`, `Documentation`, `Testing`

## Checklist

> Before a new release, perform the following tasks

- Code: Update the version name defined in [ContractVersion.sol](contracts/libraries/ContractVersion.sol)
- Verify the OpenZeppelin version matches the version required by the pinned CMTAT submodule: `npm run check:oz`
- Run linter

> npm run-script lint:all:prettier

- Documentation
  - Perform a code coverage and update the files in the corresponding directory [./doc/coverage](./doc/coverage)
  - Perform an audit with several audit tools (e.g Slither), update the report in the corresponding directory  [./doc/audits/](./doc/audits/)
  - Update surya doc by running the 3 scripts in [./doc/script](./doc/script)
  
  - Update changelog



## 0.5.0 - 2026/08/24

Branch: `style`

Commit: _pending release commit_

> Documentation, code-comment and dependency release. No factory API or storage change since `0.4.0`; the only
> source-level change to the factories is the `version()` string. The deployed CMTAT implementation bytecode does
> change, because the vendored CMTAT submodule and OpenZeppelin move forward.

### Added

- `ICMTATFactory` ([`contracts/interfaces/ICMTATFactory.sol`](contracts/interfaces/ICMTATFactory.sol)): the
  deployment-registry and salt surface every factory exposes identically - `CMTATProxyAddress`, `cmtatsList`,
  `cmtatCounterId`, `useCustomSalt`, `nextDeploymentSalt`, `isCustomSaltUsed`, `CMTAT_DEPLOYER_ROLE` and the
  `CMTATDeployed` event. **It has no imports**, so an indexer or integrating contract can compile against it
  without the CMTAT submodule or OpenZeppelin; previously the only way to call a factory was to import the
  concrete contract and its whole dependency graph. It is inherited (so the compiler enforces the match, not a
  comment) and advertised through ERC-165 `supportsInterface`. The deployment entrypoints are deliberately not
  declared: their shapes differ across the family, their arguments are CMTAT types, and `deployCMTAT` returns the
  concrete proxy type rather than `address`. Costs **+26 bytes** per factory and leaves the ABI shape unchanged.
  Finding J-3 of the v0.5.0 code-quality review; covered by `test/FactoryInterface.test.js`.
- `ICMTATFactory` ([`contracts/interfaces/ICMTATFactory.sol`](contracts/interfaces/ICMTATFactory.sol)): the
  deployment-registry and salt surface every factory exposes identically - `CMTATProxyAddress`, `cmtatsList`,
  `cmtatCounterId`, `useCustomSalt`, `nextDeploymentSalt`, `isCustomSaltUsed`, `CMTAT_DEPLOYER_ROLE` and the
  `CMTATDeployed` event. **It has no imports**, so an indexer or integrating contract can compile against it
  without the CMTAT submodule or OpenZeppelin; previously the only way to call a factory was to import the
  concrete contract and its whole dependency graph. It is inherited (so the compiler enforces the match, not a
  comment) and advertised through ERC-165 `supportsInterface`. The deployment entrypoints are deliberately not
  declared: their shapes differ across the family, their arguments are CMTAT types, and `deployCMTAT` returns the
  concrete proxy type rather than `address`. Costs **+26 bytes** per factory and leaves the ABI shape unchanged.
  Finding J-3 of the v0.5.0 code-quality review; covered by `test/FactoryInterface.test.js`.
- `isCustomSaltUsed(bytes32 salt)` on every factory: whether a custom salt has already been consumed, so
  `deployCMTAT(...)` with it would revert `CMTAT_Factory_SaltAlreadyUsed`. Previously `customSaltUsed` was
  `internal`, and the address predictors keep answering for a consumed salt (the CREATE2 address is still
  correct, it just can no longer be reached) - so an integrator had no on-chain way to tell a live prediction
  from a dead one short of sending a transaction and watching it revert. Returns `false` in counter mode, which
  never records a salt. Finding H-1 of the v0.5.0 code-quality review; covered by `test/CustomSalt.test.js`.

### Changed

- Bumped the factory version constant to `0.5.0` (`ContractVersion.sol`) and synced every mirror (`package.json`,
  `package-lock.json`, the `version()` test, `README.md`, `doc/README.md`, `AGENTS.md` / `CLAUDE.md`).
- Reordered functions and modifier keywords across the contracts to follow the Solidity style guide
  (constructor / external / public / internal / private, `view` and `pure` last; visibility before mutability
  before `virtual` / `override` before custom modifiers). Member moves only, no logic change.
- `.gitignore`: ignore LibreOffice lock files (`.~lock.*#`).
- `_deployAndRegisterProxy` caches `cmtatCounterId` in a local instead of loading the slot twice (once for the event, once for the increment): **114 gas** per deployment, measured. Finding B-1 of the v0.5.0 code-quality review.
- Marked every `internal` function `virtual` (18 additions across 8 files), so the internal surface is now 20/20
  and matches the public one, which was already 13/13. Previously the rule was applied inconsistently - inside
  `CMTATFactoryRoot`, `_deployAndRegisterProxy` sat between two `virtual` siblings without the keyword - which
  left the deployment funnel and the `_checkProxyAdminOwner` validation hook impossible to override without
  forking the base contract. The **runtime bytecode is byte-identical** for all five factories (verified with the
  solc metadata trailer stripped), so this costs nothing to deploy or run. Finding E-1 of the v0.5.0 code-quality
  review; the two highest-consequence hooks are covered by `test/VirtualOverride.test.js`.

### Dependencies

- Updated the Hardhat Solidity compiler from `0.8.34` to `0.8.36` (`hardhat.config.js`), matching the compiler
  the pinned CMTAT submodule builds with. Source pragmas stay `^0.8.20`; the EVM target stays `prague`.
- Updated the pinned CMTAT submodule from `v3.3.0-rc1` to
  [`v3.3.0-rc3`](https://github.com/CMTA/CMTAT/releases/tag/v3.3.0-rc3).
- Updated OpenZeppelin Contracts and Contracts-Upgradeable from `5.6.1` to
  [`5.7.0`](https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.7.0).
- Relaxed the `npm run check:oz` guard (`scripts/check-oz-version.js`) from an exact-range match to a
  **same-major floor**: it still fails when the factory's OpenZeppelin is older than, or on a different major to,
  the version the pinned CMTAT submodule declares - the duplicate `Initializable` breakage the guard was written
  for - but a newer OZ within the same major is now reported as a warning instead of an error. This is what CMTAT
  `v3.3.0-rc3` needs, since it still pins OZ `5.6.1` exactly while the factory runs `5.7.0` (compiles clean, all
  42 tests pass).

### Documentation

- Split the README in two: the root [`README.md`](README.md) is now a short overview (factory table, key features,
  common API, quick start, documentation index, security), and the full specification moved to
  [`doc/README.md`](doc/README.md) with all relative links rewritten for its new location.
- Completed NatSpec coverage across `contracts/`: every contract, interface, library, struct, event, state
  variable, constant and function now carries a `/** */` block, with one `@param` per argument and one `@return`
  per return value. Comment-only change, verified by the style checker and by a full compile.
- Fixed the stale `ContractVersion` version shown in the library-contracts table (was `"0.3.0"`).
- Added the versioned specification PDF (`doc/specification/CMTATFactorySpecificationV0.4.0.pdf`) and its
  cover page sources (`coverpage.odg`, `coverpage.pdf`).
- Disclosed the use of AI coding assistants (Claude Code, Codex) in both READMEs.
- Added a PlantUML diagram directory (`doc/schema/plantuml/`) holding both the `.puml` sources and their renders.
  Added an `Overview` diagram (deployer -> factory -> CREATE2 proxy -> CMTAT implementation, with the
  factory/proxy/implementation matrix) to the top of both READMEs, and replaced the drawio export of the beacon
  factory with `beacon-factory.png`. The redrawn beacon diagram corrects a stale label: the implementation behind
  `CMTAT_BEACON_FACTORY` is `CMTATStandardUpgradeable`, not `CMTATUpgradeable`, and it now also shows that the
  beacon is created once in the factory constructor. Removed the superseded
  `doc/schema/drawio/factory-BeaconFactory.drawio.png` (the `factory.drawio` source is kept - it still backs the
  transparent-factory diagram).
- Added a code-quality review for v0.5.0 ([`doc/audits/v0.5.0/CLAUDE_ANALYSIS.md`](doc/audits/v0.5.0/CLAUDE_ANALYSIS.md)),
  produced with Claude Code and registered in [`AUDIT_OVERVIEW.md`](doc/audits/AUDIT_OVERVIEW.md). It reports no
  vulnerabilities. Applied from it: a measured 114-gas saving in `_deployAndRegisterProxy` (the deployment
  counter was loaded twice; the optimizer does not forward the load across the emit), and four documentation
  corrections - the agent-guide file tree omitted three of the seven `libraries/` files, "all three factories"
  and "three factory families" should read five and four, `VERSION` belongs to `ContractVersion` rather than
  `CMTATFactoryRoot`, and the root README API sketch declared the entrypoints `external` returning `address`
  when they are `public` and return the concrete proxy type. Two findings are left open for a maintainer
  decision: `virtual` consistency on internal functions, and the lack of a public getter for `customSaltUsed`.

## 0.4.0 - 2026/07/03

Commit: _pending release commit_

> The fix commits for the Nethermind AuditAgent findings (NM-1, NM-2) are slated for this release. The version
> constant is bumped now; the hardening commits land under this entry as they are made.

### Security

- Reviewed the Nethermind **AuditAgent** v0.3.0 report and added per-finding triage. **NM-1** (Low): the
  counter-derived next-address helpers (`computedNextProxyAddress` / `nextDeploymentSalt`) are front-runnable
  across authorized deployers, because in counter mode the effective CREATE2 salt is the shared
  `keccak256(cmtatCounterId)`. **NM-2** (Info): that same counter-derived salt can be reused under reentrant proxy
  initialization, since `Create2.deploy` runs before `++cmtatCounterId`. See
  [`doc/audits/v0.3.0/audit_agent_report-feedback.md`](doc/audits/v0.3.0/audit_agent_report-feedback.md).
- **NM-1 documentation clarification.** Added a `WARNING` NatSpec block to `nextDeploymentSalt()` and to
  `computedNextProxyAddress(...)` on all five factories, plus a warning callout in the README "Salt behavior"
  section, stating that in counter mode (`useCustomSalt == false`) a predicted address is only valid until the next
  deployment by any authorized deployer, and that the safer mode is custom salts (`useCustomSalt == true`) with a
  unique, caller-chosen, one-time-use salt. Documentation-only; no behavior change.
- **NM-2 reentrancy guard.** Each concrete factory inherits OpenZeppelin `ReentrancyGuard` (co-located with usage)
  and marks its public `deployCMTAT(...)` entrypoint `nonReentrant`. This prevents a
  reentrant `deployCMTAT(...)` — triggered during a proxy's constructor/initializer, before `++cmtatCounterId` — from
  observing the same `cmtatCounterId` and reusing the auto-derived salt, so every automatic deployment keeps a
  distinct counter and salt. The guard is declared first in the modifier list (`nonReentrant onlyRole(...)`) per
  the Aderyn best-practice check.

### Changed

- Bumped the factory version constant to `0.4.0` (`ContractVersion.sol`) and synced every mirror (`package.json`,
  the `version()` test, README, `AGENTS.md` / `CLAUDE.md`).

### Documentation

- Added the Nethermind AuditAgent v0.3.0 report (`doc/audits/v0.3.0/audit_agent_report_v0.3.0.pdf`) and its
  per-finding triage feedback, and recorded both in [`doc/audits/AUDIT_OVERVIEW.md`](doc/audits/AUDIT_OVERVIEW.md)
  (neither finding exploitable; both hardened in this release — NM-1 docs warning, NM-2 reentrancy guard).
- Added `doc/script/convert_links_for_pdf.sh`, a helper that rewrites relative Markdown links to GitHub URLs for
  PDF generation while preserving image and external links.
- Added versioned Slither (0.11.5) and Aderyn (0.6.5) static-analysis reports for v0.4.0 under `doc/audits/v0.4.0/`
  with per-finding triage feedback (both tools: nothing to fix). The Aderyn set matches v0.3.0 (1 High false
  positive + 4 by-design/environment Lows); Slither's factory-scoped result stays 0.

### Testing

- Added `test/UUPS/ReentrancyGuard.test.js` and `contracts/mocks/ReentrancyDeployMock.sol`: a malicious `logic`
  mock re-enters `deployCMTAT` from the proxy initializer through a role-holding attacker. The armed case reverts
  and registers nothing (the `nonReentrant` guard fires); a disarmed control deployment succeeds — isolating the
  guard as the cause (NM-2). Suite: 42 passing.

## 0.3.0 - 2026/06/30

Commit: `18a8e66c70c810647694e5dc436e895a07016ec8`

### Added

- CMTAT Light factories `CMTAT_LIGHT_TP_FACTORY` and `CMTAT_LIGHT_BEACON_FACTORY` (`contracts/light/`) deploying the lighter `CMTATUpgradeableLight` implementation through the smaller `CMTAT_LIGHT_ARGUMENT` initializer struct.
- ERC-8303 factory version support: `version()` exposed through `IERC8303` / `ContractVersion`, with matching ERC-165 `supportsInterface`.
- Rich deployment event `CMTATDeployed(address indexed proxy, address indexed deployer, uint256 indexed id, bytes32 salt)`, emitted on every deployment.
- Deployment-salt helpers for address prediction: `nextDeploymentSalt()` and `computedNextProxyAddress(...)` on every factory.
- `npm run check:oz` script (also run in CI) that fails the build if the installed OpenZeppelin version diverges from the version required by the pinned CMTAT submodule.

### Changed

- Reorganised factory contracts into `contracts/standard/` and `contracts/light/` folders.
- Shared transparent and beacon deployment logic into new base contracts `CMTATTransparentFactoryBase` and `CMTATBeaconFactoryBase`.
- Removed redundant beacon access-control inheritance and made factory-error imports explicit.
- Removed the redundant `cmtats` mapping — `CMTATProxyAddress(id)` now reads `cmtatsList` (with a bounds guard returning the zero address for unknown ids), saving one storage write per deployment.
- Assigned `useCustomSalt` unconditionally in the constructor and removed a no-op `bytes32(...)` cast in `nextDeploymentSalt()`.
- Set the `package.json` `version` field to `0.3.0`.

### Removed

- Removed the legacy `CMTAT(address indexed, uint256)` event, superseded by `CMTATDeployed` (which carries the same proxy address and id plus the `deployer` and `salt`).

### Fixed

- Validate the transparent proxy admin owner is non-zero (`CMTAT_Factory_AddressZeroNotAllowedForProxyAdminOwner`).
- Fix proxy creation bytecode assembly for the Light factories.

### Dependencies

- Update Solidity (Hardhat compiler) to v0.8.34.
- Update CMTAT to v3.3.0-rc1.
- Update OpenZeppelin (Contracts & Contracts-Upgradeable) to v5.6.1 — required by CMTAT v3.3.0-rc1 and resolves a duplicate `Initializable` declaration that broke compilation under v5.4.0.

### Documentation

- Major README overhaul: document all five factories including the Light variants, the ERC-8303 `version()`, deployment events, and the salt / address-prediction API; correct the `Engine` ABI encoding, the Transparent `deployCMTAT` return type, and contract paths; complete the library-contracts section and regenerate the Surya diagrams.
- Added README sections: a generated table of contents, `CREATE` vs `CREATE2` deterministic deployment, a Transparent/UUPS/Beacon proxy comparison table, and a CMTAT Standard vs Light overview.
- Added `@return` NatSpec to `computedProxyAddress` (Transparent/UUPS), fixed the `beaconImplementation` casing, and linked ERC-8303 to its draft PR (not yet published as an EIP page).
- Added versioned Slither and Aderyn static-analysis reports for v0.3.0 with per-finding triage feedback, and a consolidated [`doc/audits/AUDIT_OVERVIEW.md`](doc/audits/AUDIT_OVERVIEW.md) (both tools: nothing to fix).

### Testing

- Added tests for the proxy registry (the emitted `CMTATDeployed` address, `cmtatsList(id)`, and `CMTATProxyAddress(id)` all agree, in both counter-salt and custom-salt modes; unknown ids return the zero address), the `useCustomSalt` getter (true/false), a uniform `version()` across all five factories, and `supportsInterface` for the inherited ERC-165 and AccessControl interface ids (exercising the `super` chain in `ContractVersion`).

## 0.2.0

Commit: `4d666f6639ed2197540bd41a5f51b87dd64dba50`

- Update CMTAT to v.3.0.0
- Update OpenZeppelin to v5.4.0
- Update Solidity to v0.8.30
- Improve code and documentation

## 0.1.0

Commit: `036a7c75fd1a1b3f878f079110b969a465c78ea0`

First release !
