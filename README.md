# CMTAT Factory

Factory contracts to deploy [**CMTAT**](https://github.com/CMTA/CMTAT) security tokens behind upgradeable proxies, at **deterministic addresses** (`CREATE2`) and under **role-based access control**.

> **Note:** This project has not undergone an audit and is provided as-is without any warranties.

📖 **Full documentation / specification: [doc/README.md](./doc/README.md)**

## Overview

![CMTAT Factory overview](./doc/schema/plantuml/overview.png)

_Diagram source: [`doc/schema/plantuml/overview.puml`](./doc/schema/plantuml/overview.puml)._

## Factories

| Factory | Proxy | Implementation | Contract |
| --- | --- | --- | --- |
| `CMTAT_UUPS_FACTORY` | `ERC1967Proxy` (UUPS) | `CMTATUpgradeableUUPS` | [contracts/standard/CMTAT_UUPS_FACTORY.sol](./contracts/standard/CMTAT_UUPS_FACTORY.sol) |
| `CMTAT_TP_FACTORY` | `TransparentUpgradeableProxy` | `CMTATStandardUpgradeable` | [contracts/standard/CMTAT_TP_FACTORY.sol](./contracts/standard/CMTAT_TP_FACTORY.sol) |
| `CMTAT_BEACON_FACTORY` | `BeaconProxy` (shared `UpgradeableBeacon`) | `CMTATStandardUpgradeable` | [contracts/standard/CMTAT_BEACON_FACTORY.sol](./contracts/standard/CMTAT_BEACON_FACTORY.sol) |
| `CMTAT_LIGHT_TP_FACTORY` | `TransparentUpgradeableProxy` | `CMTATUpgradeableLight` | [contracts/light/CMTAT_LIGHT_TP_FACTORY.sol](./contracts/light/CMTAT_LIGHT_TP_FACTORY.sol) |
| `CMTAT_LIGHT_BEACON_FACTORY` | `BeaconProxy` (shared `UpgradeableBeacon`) | `CMTATUpgradeableLight` | [contracts/light/CMTAT_LIGHT_BEACON_FACTORY.sol](./contracts/light/CMTAT_LIGHT_BEACON_FACTORY.sol) |

- **Standard** factories deploy the full-featured CMTAT (RuleEngine, documents, snapshots, debt, cross-chain, meta-transactions) and take the `CMTAT_ARGUMENT` initializer struct.
- **Light** factories deploy the minimal `CMTATUpgradeableLight` (ERC-20 with mint/burn, pause, enforcement, validation, access control) and take the smaller `CMTAT_LIGHT_ARGUMENT` struct.

See [Proxy patterns: Transparent vs UUPS vs Beacon](./doc/README.md#proxy-patterns-transparent-vs-uups-vs-beacon) to choose a pattern, and [CMTAT versions: Standard vs Light](./doc/README.md#cmtat-versions-standard-vs-light) to choose an implementation.

## Key features

- **Multiple proxy types** — UUPS, Transparent, or Beacon, depending on your upgrade strategy.
- **Deterministic addresses** — proxies are deployed with `CREATE2`; `computedProxyAddress(...)` / `computedNextProxyAddress(...)` return the address before deployment.
- **Role-based security** — only holders of `CMTAT_DEPLOYER_ROLE` can deploy.
- **Deployment registry** — every proxy is indexed by an incremental id and emitted in a `CMTATDeployed` event.
- **Versioned on-chain** — factories expose [ERC-8303](https://github.com/ethereum/ERCs/pull/1819) `version()`; current version is **`0.5.0`**.

## Common API

All factories share the following surface (see [Common factory API](./doc/README.md#common-factory-api) for details):

```solidity
// returns the concrete proxy type: ERC1967Proxy, TransparentUpgradeableProxy or BeaconProxy
function deployCMTAT(bytes32 deploymentSaltInput, /* [address proxyAdminOwner,] */ CMTAT_ARGUMENT calldata) public returns (Proxy);
function computedProxyAddress(bytes32 deploymentSalt, /* [address proxyAdminOwner,] */ CMTAT_ARGUMENT calldata) public view returns (address);
function computedNextProxyAddress(/* ... same trailing args ... */) public view returns (address);
function nextDeploymentSalt() public view returns (bytes32);
function CMTATProxyAddress(uint256 id) public view returns (address);
function version() public view returns (string memory);

event CMTATDeployed(address indexed proxy, address indexed deployer, uint256 indexed id, bytes32 salt);
```

> **⚠️ Salt mode.** With `useCustomSalt == false` the salt is derived from the shared `cmtatCounterId`, so a predicted address can be taken by another deployer. Prefer `useCustomSalt == true` with a unique caller-chosen salt to reserve an address. See [Salt behavior](./doc/README.md#salt-behavior).

## Quick start

```bash
git clone git@github.com:CMTA/CMTATFactory.git --recurse-submodules
cd CMTATFactory
nvm use            # Node 20.5.0
npm install
npx hardhat test
```

Other useful commands:

```bash
npx hardhat compile
npm run coverage       # solidity-coverage
npm run size           # hardhat-contract-sizer
npm run lint:sol       # solhint (add :fix to autofix)
npm run lint:js        # eslint  (add :fix to autofix)
```

> **AI assistance:** Parts of this project were written with the help of AI coding assistants, principally Claude Code (Anthropic) and Codex (OpenAI).

**Toolchain:** Hardhat `^2.26.1`, Node `20.5.0`, Solidity [`0.8.36`](https://docs.soliditylang.org/en/v0.8.36/) (EVM `prague`), CMTAT [`v3.3.0-rc3`](https://github.com/CMTA/CMTAT/releases/tag/v3.3.0-rc3), OpenZeppelin Contracts (+ Upgradeable) [`v5.7.0`](https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.7.0).

## Documentation

| Document | Content |
| --- | --- |
| [doc/README.md](./doc/README.md) | Full specification: architecture, library contracts, `CREATE2`, salt behavior, per-factory API, diagrams |
| [doc/TOOLCHAIN.md](./doc/TOOLCHAIN.md) | Toolchain details |
| [doc/Solidity-API-Docgen.md](./doc/Solidity-API-Docgen.md) | Generated Solidity API reference |
| [doc/audits/AUDIT_OVERVIEW.md](./doc/audits/AUDIT_OVERVIEW.md) | Static-analysis reports and triage |
| [doc/schema/](./doc/schema/) | PlantUML architecture diagrams (`plantuml/`, sources + renders), Surya inheritance / call graphs, drawio diagrams |

## Security

- **Vulnerability disclosure:** see [SECURITY.md](https://github.com/CMTA/CMTAT/blob/master/SECURITY.md) in the CMTAT main repository.
- **Audit:** this project has not undergone a formal audit.
- **Static analysis:** Slither, Aderyn, and Nethermind AuditAgent reports are versioned under [doc/audits/](./doc/audits/). For v0.4.0, neither Slither nor Aderyn reports anything to fix.

## Further reading

Taurus blog: [Making CMTAT Tokenization More Scalable and Cost-Effective with Proxy and Factory Contracts](https://www.taurushq.com/blog/cmtat-tokenization-deployment-with-proxy-and-factory/) (written for factory release `0.1.0`).

## Intellectual property

The code is copyright (c) Capital Market and Technology Association, 2025-2026, and is released under [Mozilla Public License 2.0](./LICENSE.md).
