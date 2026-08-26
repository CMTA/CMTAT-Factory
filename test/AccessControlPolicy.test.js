const { expect } = require('chai')
const {
  ZERO_ADDRESS,
  CMTAT_DEPLOYER_ROLE,
  DEFAULT_ADMIN_ROLE,
  extraInformationAttributes
} = require('./utils.js')
const {
  deployCMTATProxyImplementation,
  deployCMTATProxyUUPSImplementation,
  fixture,
  loadFixture
} = require('../CMTAT/test/deploymentUtils.js')
const { ethers } = require('hardhat')

const DEPLOYMENT_DECIMAL = 0
const ERC173_INTERFACE_ID = '0x7f5828d0'
const ACCESS_CONTROL_INTERFACE_ID = '0x7965db0b'

// The five factory families, each in both access-control variants. `args` builds the
// constructor arguments for a given authority address (admin or owner).
const FAMILIES = [
  {
    label: 'UUPS',
    accessControl: 'CMTAT_UUPS_FACTORY',
    ownable: 'CMTAT_UUPS_FACTORY_Ownable2Step',
    impl: 'UUPS_IMPL',
    args: (t, authority) => [t.IMPL, authority, false],
    deployArgs: (t) => [t.salt, t.cmtatArgument]
  },
  {
    label: 'Transparent',
    accessControl: 'CMTAT_TP_FACTORY',
    ownable: 'CMTAT_TP_FACTORY_Ownable2Step',
    impl: 'STANDARD_IMPL',
    args: (t, authority) => [t.IMPL, authority, false],
    deployArgs: (t) => [t.salt, t.proxyAdminOwner, t.cmtatArgument]
  },
  {
    label: 'Beacon',
    accessControl: 'CMTAT_BEACON_FACTORY',
    ownable: 'CMTAT_BEACON_FACTORY_Ownable2Step',
    impl: 'STANDARD_IMPL',
    args: (t, authority) => [t.IMPL, authority, authority, false],
    deployArgs: (t) => [t.salt, t.cmtatArgument]
  },
  {
    label: 'Light Transparent',
    accessControl: 'CMTAT_LIGHT_TP_FACTORY',
    ownable: 'CMTAT_LIGHT_TP_FACTORY_Ownable2Step',
    impl: 'LIGHT_IMPL',
    args: (t, authority) => [t.IMPL, authority, false],
    deployArgs: (t) => [t.salt, t.proxyAdminOwner, t.lightArgument]
  },
  {
    label: 'Light Beacon',
    accessControl: 'CMTAT_LIGHT_BEACON_FACTORY',
    ownable: 'CMTAT_LIGHT_BEACON_FACTORY_Ownable2Step',
    impl: 'LIGHT_IMPL',
    args: (t, authority) => [t.IMPL, authority, authority, false],
    deployArgs: (t) => [t.salt, t.lightArgument]
  }
]

describe('Factory access-control policy', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture))

    this.STANDARD_IMPL = (
      await deployCMTATProxyImplementation(
        this._.address,
        this.deployerAddress.address
      )
    ).target
    this.UUPS_IMPL = (
      await deployCMTATProxyUUPSImplementation(
        this._.address,
        this.deployerAddress.address
      )
    ).target
    this.LIGHT_IMPL = (
      await ethers.deployContract('CMTATUpgradeableLight')
    ).target

    this.salt = ethers.encodeBytes32String('policy')
    this.proxyAdminOwner = this.admin
    this.cmtatArgument = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL],
      extraInformationAttributes,
      [ZERO_ADDRESS]
    ]
    this.lightArgument = [
      this.admin,
      ['CMTA Token', 'CMTAT', DEPLOYMENT_DECIMAL]
    ]
  })

  for (const family of FAMILIES) {
    context(`${family.label} — AccessControl variant`, function () {
      beforeEach(async function () {
        this.IMPL = this[family.impl]
        this.FACTORY = await ethers.deployContract(
          family.accessControl,
          family.args(this, this.admin)
        )
      })

      it('testCanDeployWithTheDeployerRole', async function () {
        await this.FACTORY.connect(this.admin).deployCMTAT(
          ...family.deployArgs(this)
        )
        expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
      })

      it('testCannotDeployWithoutTheDeployerRole', async function () {
        await expect(
          this.FACTORY.connect(this.address1).deployCMTAT(
            ...family.deployArgs(this)
          )
        )
          .to.be.revertedWithCustomError(
            this.FACTORY,
            'AccessControlUnauthorizedAccount'
          )
          .withArgs(this.address1.address, CMTAT_DEPLOYER_ROLE)
      })

      it('testCanDeployOnceGrantedTheDeployerRole', async function () {
        // Arrange: the grant is what changes the answer, nothing else
        await this.FACTORY.connect(this.admin).grantRole(
          CMTAT_DEPLOYER_ROLE,
          this.address1
        )

        // Act
        await this.FACTORY.connect(this.address1).deployCMTAT(
          ...family.deployArgs(this)
        )

        // Assert
        expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
      })

      it('testCannotDeployWithAnUnrelatedRole', async function () {
        // Arrange: role separation is real — admin rights are not deploy rights
        await this.FACTORY.connect(this.admin).grantRole(
          DEFAULT_ADMIN_ROLE,
          this.address1
        )
        await this.FACTORY.connect(this.admin).revokeRole(
          CMTAT_DEPLOYER_ROLE,
          this.address1
        )

        // Act + Assert
        await expect(
          this.FACTORY.connect(this.address1).deployCMTAT(
            ...family.deployArgs(this)
          )
        ).to.be.revertedWithCustomError(
          this.FACTORY,
          'AccessControlUnauthorizedAccount'
        )
      })

      it('testCannotDeployAfterTheRoleIsRevoked', async function () {
        await this.FACTORY.connect(this.admin).revokeRole(
          CMTAT_DEPLOYER_ROLE,
          this.admin
        )
        await expect(
          this.FACTORY.connect(this.admin).deployCMTAT(
            ...family.deployArgs(this)
          )
        ).to.be.revertedWithCustomError(
          this.FACTORY,
          'AccessControlUnauthorizedAccount'
        )
      })

      it('testCanAdvertiseAccessControlAndNotERC173', async function () {
        expect(
          await this.FACTORY.supportsInterface(ACCESS_CONTROL_INTERFACE_ID)
        ).to.equal(true)
        expect(
          await this.FACTORY.supportsInterface(ERC173_INTERFACE_ID)
        ).to.equal(false)
      })
    })

    context(`${family.label} — Ownable2Step variant`, function () {
      beforeEach(async function () {
        this.IMPL = this[family.impl]
        this.FACTORY = await ethers.deployContract(
          family.ownable,
          family.args(this, this.admin)
        )
      })

      it('testCanDeployAsTheOwner', async function () {
        await this.FACTORY.connect(this.admin).deployCMTAT(
          ...family.deployArgs(this)
        )
        expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
      })

      it('testCannotDeployAsANonOwner', async function () {
        await expect(
          this.FACTORY.connect(this.address1).deployCMTAT(
            ...family.deployArgs(this)
          )
        )
          .to.be.revertedWithCustomError(
            this.FACTORY,
            'OwnableUnauthorizedAccount'
          )
          .withArgs(this.address1.address)
      })

      it('testCannotPublishADeployerRoleItDoesNotEnforce', async function () {
        // The Ownable variant must not expose a role identifier it never checks
        expect(
          this.FACTORY.interface.hasFunction('CMTAT_DEPLOYER_ROLE()')
        ).to.equal(false)
        expect(
          this.FACTORY.interface.hasFunction('grantRole(bytes32,address)')
        ).to.equal(false)
      })

      it('testCannotTransferControlWithoutAcceptance', async function () {
        // Arrange: step one of two
        await this.FACTORY.connect(this.admin).transferOwnership(this.address1)

        // Assert: control has NOT moved yet
        expect(await this.FACTORY.owner()).to.equal(this.admin.address)
        await expect(
          this.FACTORY.connect(this.address1).deployCMTAT(
            ...family.deployArgs(this)
          )
        ).to.be.revertedWithCustomError(
          this.FACTORY,
          'OwnableUnauthorizedAccount'
        )
      })

      it('testCanTransferControlOnceAccepted', async function () {
        // Act: both steps
        await this.FACTORY.connect(this.admin).transferOwnership(this.address1)
        await this.FACTORY.connect(this.address1).acceptOwnership()

        // Assert: control moved, and the previous owner lost it
        expect(await this.FACTORY.owner()).to.equal(this.address1.address)
        await this.FACTORY.connect(this.address1).deployCMTAT(
          ...family.deployArgs(this)
        )
        expect(await this.FACTORY.cmtatCounterId()).to.equal(1)
        await expect(
          this.FACTORY.connect(this.admin).deployCMTAT(
            ...family.deployArgs(this)
          )
        ).to.be.revertedWithCustomError(
          this.FACTORY,
          'OwnableUnauthorizedAccount'
        )
      })

      it('testCanAdvertiseERC173AndNotAccessControl', async function () {
        expect(
          await this.FACTORY.supportsInterface(ERC173_INTERFACE_ID)
        ).to.equal(true)
        expect(
          await this.FACTORY.supportsInterface(ACCESS_CONTROL_INTERFACE_ID)
        ).to.equal(false)
      })
    })
  }
})
