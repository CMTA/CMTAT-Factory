#!/usr/bin/env node
/*
 * Guards the OpenZeppelin <-> CMTAT version coupling.
 *
 * The factory deploys the vendored CMTAT implementation, so the OpenZeppelin
 * version installed for this project MUST satisfy the version the pinned CMTAT
 * submodule requires. When they drift (e.g. factory on 5.4.0 while CMTAT needs
 * 5.6.1) compilation breaks with a duplicate `Initializable` declaration.
 *
 * This script fails (exit 1) if the installed OZ version does not satisfy the
 * range declared in CMTAT/package.json. Run it in CI before compiling/testing.
 */
const path = require('path')
const semver = require('semver')

const PACKAGES = [
  '@openzeppelin/contracts',
  '@openzeppelin/contracts-upgradeable'
]

const root = path.join(__dirname, '..')

function read(jsonPath) {
  try {
    return require(jsonPath)
  } catch (e) {
    return null
  }
}

const cmtatPkg = read(path.join(root, 'CMTAT', 'package.json'))
if (!cmtatPkg) {
  console.error(
    'check-oz-version: cannot read CMTAT/package.json — is the CMTAT submodule checked out?'
  )
  process.exit(1)
}

const cmtatDeps = {
  ...(cmtatPkg.dependencies || {}),
  ...(cmtatPkg.peerDependencies || {})
}

let failed = false
for (const name of PACKAGES) {
  const required = cmtatDeps[name]
  if (!required) {
    console.error(`check-oz-version: CMTAT does not declare ${name} — skipping`)
    continue
  }
  const installedPkg = read(path.join(root, 'node_modules', name, 'package.json'))
  if (!installedPkg) {
    console.error(`check-oz-version: ${name} is not installed (run npm install)`)
    failed = true
    continue
  }
  const installed = installedPkg.version
  if (!semver.satisfies(installed, required)) {
    console.error(
      `check-oz-version: MISMATCH for ${name}\n` +
        `  CMTAT requires: ${required}\n` +
        `  factory installed: ${installed}\n` +
        '  Align the factory dependency in package.json with the version required by the pinned CMTAT submodule.'
    )
    failed = true
  } else {
    console.log(`check-oz-version: OK ${name} ${installed} satisfies "${required}"`)
  }
}

process.exit(failed ? 1 : 0)
