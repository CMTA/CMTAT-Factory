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



## 0.4.0 - 2026/06/30

Branch: `dev`
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
- **NM-2 reentrancy guard.** `CMTATFactoryRoot` now inherits OpenZeppelin `ReentrancyGuard` and every factory's
  public `deployCMTAT(...)` entrypoint is `nonReentrant`. This prevents a
  reentrant `deployCMTAT(...)` — triggered during a proxy's constructor/initializer, before `++cmtatCounterId` — from
  observing the same `cmtatCounterId` and reusing the auto-derived salt, so every automatic deployment keeps a
  distinct counter and salt.

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
  with per-finding triage feedback (both tools: nothing to fix). Aderyn's new L-3 (`nonReentrant` not the first
  modifier) is a cosmetic note from the NM-2 guard; Slither's factory-scoped result stays 0.

### Testing

- Added `test/UUPS/ReentrancyGuard.test.js` and `contracts/mocks/ReentrancyDeployMock.sol`: a malicious `logic`
  mock re-enters `deployCMTAT` from the proxy initializer through a role-holding attacker. The armed case reverts
  and registers nothing (the `nonReentrant` guard fires); a disarmed control deployment succeeds — isolating the
  guard as the cause (NM-2). Suite: 42 passing.

## 0.3.0 - 2026/06/30

Branch: `dev`
Commit: `1c77688`

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
