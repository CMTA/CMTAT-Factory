/* global describe, beforeEach, context, it */
const { expect } = require('chai')
const { ZERO_ADDRESS, CMTAT_DEPLOYER_ROLE } = require('../utils.js')
const { fixture, loadFixture } = require('../../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')
const DEPLOYMENT_DECIMAL = 0

describe('Deploy Light Beacon with Factory', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))
    this.CMTAT_LIGHT_IMPL = await ethers.deployContract(
      'CMTATUpgradeableLight'
    )
    this.FACTORY = await ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY', [
      this.CMTAT_LIGHT_IMPL.target,
      this.admin,
      this.admin,
      false
    ])

    this.CMTATLightArg = [
      this.admin,
      ['CMTA Token Light', 'CMTATL', DEPLOYMENT_DECIMAL]
    ]
  })

  context('FactoryDeployment', function () {
    it('testCanReturnTheRightImplementation', async function () {
      expect(await this.FACTORY.implementation()).to.equal(
        this.CMTAT_LIGHT_IMPL.target
      )
    })

    it('testCanDeployFactoryWithNoImplementation', async function () {
      this.FACTORY = await ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY', [
        ZERO_ADDRESS,
        this.admin,
        this.admin,
        false
      ])
      await this.FACTORY.connect(this.admin).deployCMTAT(
        ethers.encodeBytes32String('light'),
        this.CMTATLightArg
      )
      const CMTAT_ADDRESS = await this.FACTORY.CMTATProxyAddress(0)
      const MyContract = await ethers.getContractFactory(
        'CMTATUpgradeableLight'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      expect(await CMTAT_PROXY.name()).to.equal('CMTA Token Light')
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
    })

    it('testCannotDeployIfBeaconOwnerIsZero', async function () {
      await expect(
        ethers.deployContract('CMTAT_LIGHT_BEACON_FACTORY', [
          this.CMTAT_LIGHT_IMPL.target,
          this.admin,
          ZERO_ADDRESS
        ])
      ).to.be.revertedWithCustomError(
        this.FACTORY,
        'CMTAT_Factory_AddressZeroNotAllowedForBeaconOwner'
      )
    })
  })

  context('Deploy CMTAT Light with Factory', function () {
    it('testCannotBeDeployedByAttacker', async function () {
      await expect(
        this.FACTORY.connect(this.attacker).deployCMTAT(
          ethers.encodeBytes32String('light'),
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
      const deploymentSaltInput = ethers.encodeBytes32String('light')
      const computedCMTATAddress = await this.FACTORY.computedProxyAddress(
        ethers.keccak256(ethers.solidityPacked(['uint256'], [0x0])),
        this.CMTATLightArg
      )
      expect(
        await this.FACTORY.computedNextProxyAddress(
          deploymentSaltInput,
          this.CMTATLightArg
        )
      ).to.equal(computedCMTATAddress)

      await this.FACTORY.connect(this.admin).deployCMTAT(
        deploymentSaltInput,
        this.CMTATLightArg
      )

      const filter = this.FACTORY.filters.CMTATDeployed
      const events = await this.FACTORY.queryFilter(filter, -1)
      const args = events[0].args
      expect(args[2]).to.equal(0)

      const CMTAT_ADDRESS = args[0]
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(CMTAT_ADDRESS)
      expect(await this.FACTORY.CMTATProxyAddress(0)).to.equal(
        computedCMTATAddress
      )

      const MyContract = await ethers.getContractFactory(
        'CMTATUpgradeableLight'
      )
      const CMTAT_PROXY = MyContract.attach(CMTAT_ADDRESS)
      expect(await CMTAT_PROXY.symbol()).to.equal('CMTATL')
      await CMTAT_PROXY.connect(this.admin).mint(this.admin, 100)
    })
  })
})
