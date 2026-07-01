const { expect } = require('chai')
const {
  ZERO_ADDRESS,
  CMTAT_DEPLOYER_ROLE,
  extraInformationAttributes
} = require('../utils.js')
const { fixture, loadFixture } = require('../../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')

const DEPLOYMENT_DECIMAL = 0

// Regression test for Nethermind AuditAgent NM-2: a deployCMTAT re-entry triggered from a proxy's
// initializer (before cmtatCounterId is incremented) must be rejected by the nonReentrant guard on
// the shared deployment funnel CMTATFactoryRoot._deployAndRegisterProxy.
describe('Factory reentrancy guard (AuditAgent NM-2)', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))

    // Attacker holds CMTAT_DEPLOYER_ROLE so its re-entrant deployCMTAT reaches the guard (not onlyRole).
    this.attackerContract = await ethers.deployContract('ReentrancyDeployAttacker', [])
    // Malicious "logic": its fallback runs under the proxy's delegatecall and calls the attacker.
    this.logicMock = await ethers.deployContract('ReentrantInitLogicMock', [
      this.attackerContract.target
    ])
    // Counter-salt mode (useCustomSalt = false) — the mode NM-2 is about.
    this.FACTORY = await ethers.deployContract('CMTAT_UUPS_FACTORY', [
      this.logicMock.target,
      this.admin,
      false
    ])

    this.CMTATArg = [
      this.admin.address,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]

    await this.FACTORY.connect(this.admin).grantRole(
      CMTAT_DEPLOYER_ROLE,
      this.attackerContract.target
    )

    // Pre-encode the nested deployCMTAT call the attacker will replay during construction.
    this.reentrantCall = this.FACTORY.interface.encodeFunctionData('deployCMTAT', [
      ethers.encodeBytes32String('reenter'),
      this.CMTATArg
    ])
  })

  it('testReentrantDeployIsBlockedByGuard', async function () {
    // Arm the attacker: the initializer will re-enter deployCMTAT mid-deployment.
    await this.attackerContract.configure(
      this.FACTORY.target,
      this.reentrantCall,
      true
    )

    await expect(
      this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('outer'),
        this.CMTATArg
      )
    ).to.be.reverted

    // Nothing was registered: the whole deployment reverted.
    expect(await this.FACTORY.cmtatCounterId()).to.equal(0)
    expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(ZERO_ADDRESS)
  })

  it('testNonReentrantDeploySucceedsControl', async function () {
    // Same malicious logic, but disarmed: the initializer no-ops, so the deployment completes.
    // Proves the revert above is specifically the re-entry, not the mock plumbing or the role.
    await this.attackerContract.configure(
      this.FACTORY.target,
      this.reentrantCall,
      false
    )

    await expect(
      this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('outer'),
        this.CMTATArg
      )
    ).to.emit(this.FACTORY, 'CMTATDeployed')

    expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
  })
})
