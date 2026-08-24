const { expect } = require('chai')
const { ZERO_ADDRESS, extraInformationAttributes } = require('./utils.js')
const {
  deployCMTATProxyImplementation,
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')

const DEPLOYMENT_DECIMAL = 0
const BLOCKED_PROXY_ADMIN_OWNER = '0x000000000000000000000000000000000000dEaD'

// These tests guard the `virtual` keyword on the factories' internal extension
// points. Compiling the mocks proves the keyword is present; the assertions
// below prove the override is actually reached, which a compile-only harness
// would not catch if a subclass silently shadowed a non-virtual member.
describe('Factory internal override points', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTATArg = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]
    this.salt = ethers.encodeBytes32String('override-guard')
  })

  context('_deployAndRegisterProxy', function () {
    beforeEach(async function () {
      this.IMPL = await deployCMTATProxyUUPSImplementation(
        this._.address,
        this.deployerAddress.address
      )
      this.FACTORY = await ethers.deployContract('DeployHookFactoryMock', [
        this.IMPL.target,
        this.admin,
        false
      ])
    })

    it('testCanReachTheOverriddenDeploymentFunnel', async function () {
      // Arrange
      expect(await this.FACTORY.hookCallCount()).to.equal(0)

      // Act
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.CMTATArg
      )

      // Assert: the subclass hook ran, and saw the address the base registered
      expect(await this.FACTORY.hookCallCount()).to.equal(1)
      expect(await this.FACTORY.lastRegistered()).to.equal(
        await this.FACTORY.CMTATProxyAddress(0)
      )
    })

    it('testCanKeepBaseRegistrationBehaviourUnderAnOverride', async function () {
      // Act
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.CMTATArg
      )

      // Assert: overriding the funnel does not break the id / list invariants
      expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
      expect(await this.FACTORY.cmtatsList(0)).to.equal(
        await this.FACTORY.lastRegistered()
      )
    })
  })

  context('_checkProxyAdminOwner', function () {
    beforeEach(async function () {
      this.IMPL = await deployCMTATProxyImplementation(
        this._.address,
        this.deployerAddress.address
      )
      this.FACTORY = await ethers.deployContract(
        'StrictProxyAdminFactoryMock',
        [this.IMPL.target, this.admin, false]
      )
    })

    it('testCanTightenTheProxyAdminHookThroughAnOverride', async function () {
      // Act + Assert: the subclass rule is reached from the real deploy path
      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(
          this.salt,
          BLOCKED_PROXY_ADMIN_OWNER,
          this.CMTATArg
        )
      ).to.be.revertedWithCustomError(this.FACTORY, 'ProxyAdminOwnerBlocked')
    })

    it('testCanKeepTheInheritedZeroAddressCheckUnderAnOverride', async function () {
      // Act + Assert: super() is still called, so the base rule survives
      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(
          this.salt,
          ZERO_ADDRESS,
          this.CMTATArg
        )
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_AddressZeroNotAllowedForProxyAdminOwner'
      )
    })

    it('testCanStillDeployWithAnAllowedProxyAdminOwner', async function () {
      // Act
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.admin,
        this.CMTATArg
      )

      // Assert
      expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
    })
  })
})
