const { ZERO_ADDRESS, extraInformationAttributes } = require('../utils.js')
const { expect } = require('chai')
const DEPLOYMENT_DECIMAL = 0
const {
  deployCMTATProxyImplementation,
  fixture,
  loadFixture
} = require('../../CMTAT/test/deploymentUtils.js')
describe('Deploy Beacon with Factory', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_PROXY_IMPL = await deployCMTATProxyImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.FACTORYCustomError = await ethers.deployContract(
      'CMTAT_BEACON_FACTORY',
      [this.CMTAT_PROXY_IMPL.target, this.admin, this.admin, true]
    )
    this.CMTATArg = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]
  })
  context('BeaconDeployment', function () {
    it('testCanDeployFactoryWithNoImplementation', async function () {
      this.FACTORY = await ethers.deployContract('CMTAT_BEACON_FACTORY', [
        ZERO_ADDRESS,
        this.admin,
        this.admin,
        false
      ])
      await this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('test'),
        this.CMTATArg
      )
      const CMTAT_ADDRESS = await this.FACTORY.CMTATProxyAddress(0)
      const MyContract = await ethers.getContractFactory(
        'CMTATStandardUpgradeable'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      // Act + Assert
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
    })
    it('testCannotDeployIfBeaconOwnerIsZero', async function () {
      await expect(
        ethers.deployContract('CMTAT_BEACON_FACTORY', [
          this.CMTAT_PROXY_IMPL.target,
          this.admin.address,
          ZERO_ADDRESS
        ])
      ).to.be.revertedWithCustomError(
        this.FACTORYCustomError,
        'CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner'
      )
    })
  })
})
