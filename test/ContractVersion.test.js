const { expect } = require('chai')
const {
  deployCMTATProxyImplementation,
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')

const ERC8303_INTERFACE_ID = '0x54fd4d50'
const ERC165_INTERFACE_ID = '0x01ffc9a7'
const ACCESS_CONTROL_INTERFACE_ID = '0x7965db0b'
const INVALID_INTERFACE_ID = '0xffffffff'
const FACTORY_VERSION = '0.5.0'

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
      ]),
      await ethers.deployContract('CMTAT_UUPS_FACTORY_Ownable2Step', [
        this.CMTAT_UUPS_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_TP_FACTORY_Ownable2Step', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_BEACON_FACTORY_Ownable2Step', [
        this.CMTAT_PROXY_IMPL.target,
        this.admin,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_TP_FACTORY_Ownable2Step', [
        this.CMTAT_LIGHT_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY_Ownable2Step', [
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
    // All TEN deployable factories - both access-control variants of each of the
    // five families - must report the SAME version string, so a partial version
    // bump (one factory missed) fails loudly.
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

  it('testCanAdvertiseInheritedInterfacesAcrossFactories', async function () {
    // Exercises the `super.supportsInterface` branch of ContractVersion: the
    // call must chain down to ERC165 in BOTH policies, so ERC-165 resolves to
    // true for all ten. The policy-specific id is asserted per variant in
    // AccessControlPolicy.test.js.
    for (const factory of this.factories) {
      expect(await factory.supportsInterface(ERC165_INTERFACE_ID)).to.equal(
        true
      )
    }
    // AccessControl is policy-specific: only the first five advertise it, and
    // the Ownable2Step variants must NOT - they do not enforce roles.
    for (const factory of this.factories.slice(0, 5)) {
      expect(
        await factory.supportsInterface(ACCESS_CONTROL_INTERFACE_ID)
      ).to.equal(true)
    }
    for (const factory of this.factories.slice(5)) {
      expect(
        await factory.supportsInterface(ACCESS_CONTROL_INTERFACE_ID)
      ).to.equal(false)
    }
  })
})
