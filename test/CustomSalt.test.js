const { expect } = require('chai')
const { ZERO_ADDRESS, extraInformationAttributes } = require('./utils.js')
const {
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')

const DEPLOYMENT_DECIMAL = 0

describe('Factory custom salt availability', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_PROXY_IMPL = await deployCMTATProxyUUPSImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.CMTATArg = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]
    this.salt = ethers.encodeBytes32String('one-shot-salt')
  })

  context('Custom salt mode', function () {
    beforeEach(async function () {
      this.FACTORY = await ethers.deployContract('CMTAT_UUPS_FACTORY', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        true
      ])
    })

    it('testCanReportAnUnusedCustomSaltAsAvailable', async function () {
      expect(await this.FACTORY.isCustomSaltUsed(this.salt)).to.equal(false)
    })

    it('testCanReportAConsumedCustomSaltAsUsed', async function () {
      // Act
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.CMTATArg
      )

      // Assert: the salt is now flagged, and a second deployment would revert
      expect(await this.FACTORY.isCustomSaltUsed(this.salt)).to.equal(true)
      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(this.salt, this.CMTATArg)
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_SaltAlreadyUsed'
      )
    })

    it('testCanDistinguishAConsumedSaltFromThePredictedAddress', async function () {
      // Arrange: computedProxyAddress answers the same before and after the salt
      // is consumed, so it cannot be used on its own to tell whether a
      // deployment is still available. isCustomSaltUsed is what carries that.
      const predicted = await this.FACTORY.computedProxyAddress(
        this.salt,
        this.CMTATArg
      )
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.CMTATArg
      )

      // Act + Assert
      expect(
        await this.FACTORY.computedProxyAddress(this.salt, this.CMTATArg)
      ).to.equal(predicted)
      expect(await this.FACTORY.isCustomSaltUsed(this.salt)).to.equal(true)
    })

    it('testCannotFlagAnUnrelatedCustomSalt', async function () {
      // Arrange
      const otherSalt = ethers.encodeBytes32String('another-salt')

      // Act
      await this.FACTORY.connect(this.admin).deployCMTAT(
        this.salt,
        this.CMTATArg
      )

      // Assert
      expect(await this.FACTORY.isCustomSaltUsed(otherSalt)).to.equal(false)
    })
  })

  context('Counter salt mode', function () {
    it('testCanReportNoSaltAsUsedInCounterMode', async function () {
      // Arrange: counter mode never records a salt, so nothing is ever flagged
      const factory = await ethers.deployContract('CMTAT_UUPS_FACTORY', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        false
      ])
      const effectiveSalt = await factory.nextDeploymentSalt()

      // Act
      await factory.connect(this.admin).deployCMTAT(this.salt, this.CMTATArg)

      // Assert
      expect(await factory.isCustomSaltUsed(this.salt)).to.equal(false)
      expect(await factory.isCustomSaltUsed(effectiveSalt)).to.equal(false)
    })
  })
})
