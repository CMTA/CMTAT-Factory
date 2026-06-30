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



## 0.3.0 - 2026/06/30

Branch: `dev`
Commit: _pending release commit_

### Added

- CMTAT Light factories `CMTAT_LIGHT_TP_FACTORY` and `CMTAT_LIGHT_BEACON_FACTORY` (`contracts/light/`) deploying the lighter `CMTATUpgradeableLight` implementation through the smaller `CMTAT_LIGHT_ARGUMENT` initializer struct.
- ERC-8303 factory version support: `version()` exposed through `IERC8303` / `ContractVersion`, with matching ERC-165 `supportsInterface`.
- Rich deployment event `CMTATDeployed(address indexed proxy, address indexed deployer, uint256 indexed id, bytes32 salt)`, emitted on every deployment.
- Deployment-salt helpers for address prediction: `nextDeploymentSalt()` and `computedNextProxyAddress(...)` on every factory.

### Changed

- Reorganised factory contracts into `contracts/standard/` and `contracts/light/` folders.
- Shared transparent and beacon deployment logic into new base contracts `CMTATTransparentFactoryBase` and `CMTATBeaconFactoryBase`.
- Removed redundant beacon access-control inheritance and made factory-error imports explicit.

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

## 0.2.0

Commit: `4d666f6639ed2197540bd41a5f51b87dd64dba50`

- Update CMTAT to v.3.0.0
- Update OpenZeppelin to v5.4.0
- Update Solidity to v0.8.30
- Improve code and documentation

## 0.1.0

Commit: `036a7c75fd1a1b3f878f079110b969a465c78ea0`

First release !
