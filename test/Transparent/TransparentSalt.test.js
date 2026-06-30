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
    it('testTracksProxyRegistryByIdWithCustomSalt', async function () {
      // useCustomSalt == true: deploy with two DIFFERENT caller-supplied salts.
      // The id must stay sequential and decoupled from the salt, and the registry
      // (CMTATProxyAddress / cmtatsList) must resolve each id to its proxy.
      const salt0 = ethers.encodeBytes32String('salt-0')
      const salt1 = ethers.encodeBytes32String('salt-1')
      const predicted0 = await this.FACTORY.computedProxyAddress(
        salt0,
        this.admin,
        this.CMTATArg
      )
      await this.FACTORY.connect(this.admin).deployCMTAT(
        salt0,
        this.admin,
        this.CMTATArg
      )
      const predicted1 = await this.FACTORY.computedProxyAddress(
        salt1,
        this.admin,
        this.CMTATArg
      )
      await this.FACTORY.connect(this.admin).deployCMTAT(
        salt1,
        this.admin,
        this.CMTATArg
      )
      // id is sequential, independent of the custom salts used
      expect(await this.FACTORY.cmtatCounterId()).to.equal(2)
      // registry by id resolves to the deployed (predicted) addresses
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(predicted0)
      expect(await this.FACTORY.CMTATProxyAddress(1)).to.equal(predicted1)
      // cmtatsList agrees with CMTATProxyAddress at every id
      expect(await this.FACTORY.cmtatsList(0)).to.equal(predicted0)
      expect(await this.FACTORY.cmtatsList(1)).to.equal(predicted1)
      // unknown id returns the zero address instead of reverting
      expect(await this.FACTORY.CMTATProxyAddress(2)).to.equal(ZERO_ADDRESS)
      expect(await this.FACTORY.CMTATProxyAddress(999)).to.equal(ZERO_ADDRESS)
    })
  })
})
