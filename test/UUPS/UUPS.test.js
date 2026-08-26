const { expect } = require('chai')
const {
  ZERO_ADDRESS,
  CMTAT_DEPLOYER_ROLE,
  extraInformationAttributes
} = require('../utils.js')
const {
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')
const DEPLOYMENT_DECIMAL = 0
describe('Deploy UUPPSwith Factory', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_PROXY_IMPL = await deployCMTATProxyUUPSImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.FACTORY = await ethers.deployContract('CMTAT_UUPS_FACTORY', [
      this.CMTAT_PROXY_IMPL.target,
      this.admin,
      false
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
      const effectiveDeploymentSalt = await this.FACTORY.nextDeploymentSalt()
      let computedCMTATAddress = await this.FACTORY.computedProxyAddress(
        // 0x0 => id counter 0
        effectiveDeploymentSalt,
        this.CMTATArg
      )
      expect(
        await this.FACTORY.computedNextProxyAddress(
          deploymentSaltInput,
          this.CMTATArg
        )
      ).to.equal(computedCMTATAddress)
      // Act
      this.logs = await this.FACTORY.connect(this.admin).deployCMTAT(
        deploymentSaltInput,
        this.CMTATArg
      )
      await expect(this.logs)
        .to.emit(this.FACTORY, 'CMTATDeployed')
        .withArgs(
          computedCMTATAddress,
          this.admin.address,
          0,
          effectiveDeploymentSalt
        )
      await this.logs.wait()
      const filter = this.FACTORY.filters.CMTATDeployed
      let events = await this.FACTORY.queryFilter(filter, -1)
      let args = events[0].args
      // Assert
      // Check  Id
      expect(args[2]).to.equal(0)
      let CMTAT_ADDRESS = args[0]
      // Check address with ID
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(CMTAT_ADDRESS)
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(
        computedCMTATAddress
      )
      const MyContract = await ethers.getContractFactory(
        'CMTATUpgradeableUUPS'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
      // Second deployment
      this.logs = await this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('test'),
        this.CMTATArg
      )
      // Check Id increment
      events = await this.FACTORY.queryFilter(filter, -1)
      args = events[0].args
      expect(args[2]).to.equal(1)

      // Check address
      computedCMTATAddress = await this.FACTORY.computedProxyAddress(
        ethers.keccak256(ethers.solidityPacked(['uint256'], [0x1])),
        this.CMTATArg
      )
      CMTAT_ADDRESS = args[0]
      expect(await this.FACTORY.CMTATProxyAddress(1)).to.equal(CMTAT_ADDRESS)
      expect(await this.FACTORY.CMTATProxyAddress(1)).to.equal(
        computedCMTATAddress
      )
    })
  })
})
