const { expect } = require('chai')
const {
  ZERO_ADDRESS,
  CMTAT_DEPLOYER_ROLE,
  extraInformationAttributes
} = require('../utils.js')
const {
  deployCMTATProxyImplementation,
  fixture,
  loadFixture
} = require('../../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')
const DEPLOYMENT_DECIMAL = 0
describe('Deploy TP with Factory - Salt', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_PROXY_IMPL = await deployCMTATProxyImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.FACTORY = await ethers.deployContract('CMTAT_TP_FACTORY', [
      this.CMTAT_PROXY_IMPL.target,
      this.admin,
      true
    ])
    this.CMTATArg = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]
  })

  context('FactoryDeployment', function () {
    it('testCanReturnTheRightImplementation', async function () {
      // Act + Assert
      expect(await this.FACTORY.logic()).to.equal(this.CMTAT_PROXY_IMPL.target)
    })
  })

  context('Deploy CMTAT with Factory', function () {
    it('testCannotBeDeployedByAttacker', async function () {
      // Act
      await expect(
        this.FACTORY.connect(this.attacker).deployCMTAT(
          ethers.encodeBytes32String('test'),
          this.admin,
          this.CMTATArg
        )
      )
        .to.be.revertedWithCustomError(
          this.FACTORY,
          'AccessControlUnauthorizedAccount'
        )
        .withArgs(this.attacker.address, CMTAT_DEPLOYER_ROLE)
    })
    it('testCanDeployCMTATWithFactory', async function () {
      const deploymentSaltInput = ethers.encodeBytes32String('test')
      expect(
        await this.FACTORY.computedNextProxyAddress(
          deploymentSaltInput,
          this.admin,
          this.CMTATArg
        )
      ).to.equal(
        await this.FACTORY.computedProxyAddress(
          deploymentSaltInput,
          this.admin,
          this.CMTATArg
        )
      )
      // Act
      this.logs = await this.FACTORY.connect(this.admin).deployCMTAT(
        deploymentSaltInput,
        this.admin,
        this.CMTATArg
      )
      // Assert
      // Check  Id
      await this.logs.wait()
      const filter = this.FACTORY.filters.CMTATDeployed
      let events = await this.FACTORY.queryFilter(filter, -1)
      let args = events[0].args
      expect(args[2]).to.equal(0)
      const CMTAT_ADDRESS = args[0]
      const MyContract = await ethers.getContractFactory(
        'CMTATStandardUpgradeable'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      // Check address with ID
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(CMTAT_ADDRESS)
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
      // Second deployment
      this.logs = await this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('test2'),
        this.admin,
        this.CMTATArg
      )
      // Check Id increment
      events = await this.FACTORY.queryFilter(filter, -1)
      args = events[0].args
      expect(args[2]).to.equal(1)
      // Revert
      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(
          ethers.encodeBytes32String('test'),
          this.admin,
          this.CMTATArg
        )
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_SaltAlreadyUsed'
      )
    })
    it('testCannotDeployCMTATWithFactoryWithSaltAlreadyUsed', async function () {
      // Arrange
      await this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('test'),
        this.admin,
        this.CMTATArg
      )

      // Act with Revert
      await expect(
        this.FACTORY.connect(this.admin).deployCMTAT(
          ethers.encodeBytes32String('test'),
          this.admin,
          this.CMTATArg
        )
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_SaltAlreadyUsed'
      )
    })
  })
})
