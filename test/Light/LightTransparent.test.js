/* global describe, beforeEach, context, it */
const { expect } = require('chai')
const { ZERO_ADDRESS, CMTAT_DEPLOYER_ROLE } = require('../utils.js')
const { fixture, loadFixture } = require('../../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')
const DEPLOYMENT_DECIMAL = 0

describe('Deploy Light TP with Factory', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_LIGHT_IMPL = await ethers.deployContract('CMTATUpgradeableLight')
    this.FACTORY = await ethers.deployContract('CMTAT_LIGHT_TP_FACTORY', [
      this.CMTAT_LIGHT_IMPL.target,
      this.admin,
      true
    ])

    this.CMTATLightArg = [
      this.admin,
      ['CMTA Token Light', 'CMTATL', DEPLOYMENT_DECIMAL]
    ]
  })

  context('FactoryDeployment', function () {
    it('testCanReturnTheRightImplementation', async function () {
      expect(await this.FACTORY.logic()).to.equal(this.CMTAT_LIGHT_IMPL.target)
    })

    it('testCannotDeployIfImplementationIsZero', async function () {
      await expect(
        ethers.deployContract('CMTAT_LIGHT_TP_FACTORY', [
          ZERO_ADDRESS,
          this.admin,
          true
        ])
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_AddressZeroNotAllowedForLogicContract'
      )
    })
  })

  context('Deploy CMTAT Light with Factory', function () {
    it('testCannotBeDeployedByAttacker', async function () {
      await expect(
        this.FACTORY.connect(this.attacker).deployCMTAT(
          ethers.encodeBytes32String('light'),
          this.admin.address,
          this.CMTATLightArg
        )
      )
        .to.be.revertedWithCustomError(
          this.FACTORY,
          'AccessControlUnauthorizedAccount'
        )
        .withArgs(this.attacker.address, CMTAT_DEPLOYER_ROLE)
    })

    it('testCanDeployCMTATLightWithFactory', async function () {
      const deploymentSalt = ethers.encodeBytes32String('light')
      const computedCMTATAddress = await this.FACTORY.computedProxyAddress(
        deploymentSalt,
        this.admin,
        this.CMTATLightArg
      )
      expect(
        await this.FACTORY.computedNextProxyAddress(
          deploymentSalt,
          this.admin,
          this.CMTATLightArg
        )
      ).to.equal(computedCMTATAddress)

      this.logs = await this.FACTORY.connect(this.admin).deployCMTAT(
        deploymentSalt,
        this.admin,
        this.CMTATLightArg
      )

      const filter = this.FACTORY.filters.CMTAT
      const events = await this.FACTORY.queryFilter(filter, -1)
      const args = events[0].args
      expect(args[1]).to.equal(0)

      const CMTAT_ADDRESS = args[0]
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(CMTAT_ADDRESS)
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(
        computedCMTATAddress
      )

      const MyContract = await ethers.getContractFactory(
        'CMTATUpgradeableLight'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      expect(await CMTAT_PROXY.name()).to.equal('CMTA Token Light')
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
    })

    it('testCannotDeployCMTATLightWithSaltAlreadyUsed', async function () {
      const deploymentSalt = ethers.encodeBytes32String('light')
      await this.FACTORY.connect(this.admin).deployCMTAT(
        deploymentSalt,
        this.admin,
        this.CMTATLightArg
      )

      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(
          deploymentSalt,
          this.admin,
          this.CMTATLightArg
        )
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_SaltAlreadyUsed'
      )
    })
  })
})
