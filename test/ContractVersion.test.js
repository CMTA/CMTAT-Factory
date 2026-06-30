const { expect } = require('chai')
const {
  deployCMTATProxyImplementation,
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')

const ERC8303_INTERFACE_ID = '0x54fd4d50'
const INVALID_INTERFACE_ID = '0xffffffff'
const FACTORY_VERSION = '0.3.0'

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
    const versions = []
    for (const factory of this.factories) {
      const v = await factory.version()
      expect(v).to.equal(FACTORY_VERSION)
      versions.push(v)
    }
    // All five factories must report the SAME version string, so a partial
    // version bump (one factory missed) fails loudly.
    expect(new Set(versions).size).to.equal(1)
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
