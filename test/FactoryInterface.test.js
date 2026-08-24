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

// XOR of the selectors ICMTATFactory declares directly. It inherits nothing,
// so this is the whole set - the ERC-165 trap of missing inherited selectors
// cannot apply here.
const ICMTAT_FACTORY_SIGNATURES = [
  'CMTAT_DEPLOYER_ROLE()',
  'CMTATProxyAddress(uint256)',
  'cmtatCounterId()',
  'cmtatsList(uint256)',
  'isCustomSaltUsed(bytes32)',
  'nextDeploymentSalt()',
  'useCustomSalt()'
]

function interfaceId (signatures) {
  return ethers.hexlify(
    signatures
      .map((s) => ethers.getBytes(ethers.id(s).slice(0, 10)))
      .reduce((acc, sel) => acc.map((b, i) => b ^ sel[i]))
  )
}

describe('ICMTATFactory', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))

    this.STANDARD_IMPL = await deployCMTATProxyImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.UUPS_IMPL = await deployCMTATProxyUUPSImplementation(
      this._.address,
      this.deployerAddress.address
    )
    this.LIGHT_IMPL = await ethers.deployContract('CMTATUpgradeableLight')

    this.factories = [
      await ethers.deployContract('CMTAT_UUPS_FACTORY', [
        this.UUPS_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_TP_FACTORY', [
        this.STANDARD_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_BEACON_FACTORY', [
        this.STANDARD_IMPL.target,
        this.admin,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_TP_FACTORY', [
        this.LIGHT_IMPL.target,
        this.admin,
        false
      ]),
      await ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY', [
        this.LIGHT_IMPL.target,
        this.admin,
        this.admin,
        false
      ])
    ]
  })

  context('ERC-165 advertisement', function () {
    it('testCanAdvertiseTheFactoryInterfaceAcrossFactories', async function () {
      // Arrange
      const id = interfaceId(ICMTAT_FACTORY_SIGNATURES)

      // Act + Assert
      for (const factory of this.factories) {
        expect(await factory.supportsInterface(id)).to.equal(true)
      }
    })

    it('testCanKeepAdvertisingTheInheritedInterfaces', async function () {
      // Assert: adding the new id did not displace the existing answers
      for (const factory of this.factories) {
        expect(await factory.supportsInterface('0x01ffc9a7')).to.equal(true) // ERC-165
        expect(await factory.supportsInterface('0x7965db0b')).to.equal(true) // AccessControl
        expect(await factory.supportsInterface('0x54fd4d50')).to.equal(true) // ERC-8303
        expect(await factory.supportsInterface('0xffffffff')).to.equal(false)
      }
    })
  })

  context('Interface-only consumer', function () {
    it('testCanReadEveryFactoryThroughTheSharedInterface', async function () {
      // Act + Assert: one consumer, compiled against the interface alone,
      // reads all five factory families without knowing which is which
      for (const factory of this.factories) {
        const consumer = await ethers.deployContract('FactoryConsumerMock', [
          factory.target
        ])
        const [
          counter,
          firstProxy,
          listHeadMatchesRegistry,
          nextSalt,
          custom,
          deployerRole
        ] = await consumer.readAll()

        expect(counter).to.equal(0)
        expect(firstProxy).to.equal(ZERO_ADDRESS)
        expect(listHeadMatchesRegistry).to.equal(true)
        expect(nextSalt).to.equal(await factory.nextDeploymentSalt())
        expect(custom).to.equal(false)
        expect(deployerRole).to.equal(await factory.CMTAT_DEPLOYER_ROLE())
      }
    })

    it('testCanObserveADeploymentThroughTheSharedInterface', async function () {
      // Arrange
      const factory = this.factories[0] // UUPS
      const consumer = await ethers.deployContract('FactoryConsumerMock', [
        factory.target
      ])
      const cmtatArgument = [
        this.admin,
        ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
        extraInformationAttributes,
        [ZERO_ADDRESS]
      ]

      // Act
      await factory
        .connect(this.admin)
        .deployCMTAT(ethers.encodeBytes32String('s'), cmtatArgument)

      // Assert: the interface sees the registry the factory just wrote
      const [counter, firstProxy, listHeadMatchesRegistry] =
        await consumer.readAll()
      expect(counter).to.equal(1)
      expect(firstProxy).to.equal(await factory.CMTATProxyAddress(0))
      expect(listHeadMatchesRegistry).to.equal(true)
    })

    it('testCanReadCustomSaltStateThroughTheSharedInterface', async function () {
      // Arrange
      const factory = await ethers.deployContract('CMTAT_UUPS_FACTORY', [
        this.UUPS_IMPL.target,
        this.admin,
        true
      ])
      const consumer = await ethers.deployContract('FactoryConsumerMock', [
        factory.target
      ])
      const salt = ethers.encodeBytes32String('interface-salt')
      expect(await consumer.isSaltConsumed(salt)).to.equal(false)

      // Act
      await factory.connect(this.admin).deployCMTAT(salt, [
        this.admin,
        ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
        extraInformationAttributes,
        [ZERO_ADDRESS]
      ])

      // Assert
      expect(await consumer.isSaltConsumed(salt)).to.equal(true)
    })
  })
})
