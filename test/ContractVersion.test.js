const { expect } = require('chai')
const {
  deployCMTATProxyImplementation,
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')

const ERC8303_INTERFACE_ID = '0x54fd4d50'
const INVALID_INTERFACE_ID = '0xffffffff'
const FACTORY_VERSION = '0.2.0'

describe('Factory ContractVersion', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))

    this.CMTAT_PROXY_IMPL = await deployCMTATProxyImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.CMTAT_UUPS_IMPL = await deployCMTATProxyUUPSImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.CMTAT_LIGHT_IMPL = await ethers.deployContract('CMTATUpgradeableLight')

    this.factories = [
      await ethers.deployContract('CMTAT_UUPS_FACTORY', [
        this.CMTAT_UUPS_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_TP_FACTORY', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_BEACON_FACTORY', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_TP_FACTORY', [
        this.CMTAT_LIGHT_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY', [
        this.CMTAT_LIGHT_IMPL.target,
        this.admin,
        this.admin,
        false
      ])
    ]
  })

  it('testCanExposeERC8303VersionAcrossFactories', async function () {
    for (const factory of this.factories) {
      expect(await factory.VERSION()).to.equal(FACTORY_VERSION)
      expect(await factory.version()).to.equal(FACTORY_VERSION)
    }
  })

  it('testCanAdvertiseERC8303InterfaceAcrossFactories', async function () {
    for (const factory of this.factories) {
      expect(await factory.supportsInterface(ERC8303_INTERFACE_ID)).to.equal(
        true
      )
      expect(await factory.supportsInterface(INVALID_INTERFACE_ID)).to.equal(
        false
      )
    }
  })
})
