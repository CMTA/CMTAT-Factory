#!/usr/bin/env node
/*
 * Guards the OpenZeppelin <-> CMTAT version coupling.
 *
 * The factory deploys the vendored CMTAT implementation, so the OpenZeppelin
 * version installed for this project MUST satisfy the version the pinned CMTAT
 * submodule requires. When they drift (e.g. factory on 5.4.0 while CMTAT needs
 * 5.6.1) compilation breaks with a duplicate `Initializable` declaration.
 *
 * The coupling is a FLOOR, not an equality: the factory must never sit BELOW the
 * version CMTAT requires, and must stay on the same major. A newer OZ within the
 * same major (e.g. factory on 5.7.0 while CMTAT pins 5.6.1) compiles and tests
 * clean, so it is reported as a warning rather than a failure.
 *
 * This script fails (exit 1) when the installed OZ version is older than, or on a
 * different major to, the version declared in CMTAT/package.json. Run it in CI
 * before compiling/testing.
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
let warned = false
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
  const floor = semver.minVersion(required)
  if (!floor) {
    console.error(
      `check-oz-version: cannot parse the version range CMTAT declares for ${name}: "${required}"`
    )
    failed = true
    continue
  }

  if (semver.major(installed) !== semver.major(floor)) {
    console.error(
      `check-oz-version: MAJOR MISMATCH for ${name}\n` +
        `  CMTAT requires: ${required}\n` +
        `  factory installed: ${installed}\n` +
        '  Align the factory dependency in package.json with the major required by the pinned CMTAT submodule.'
    )
    failed = true
  } else if (semver.lt(installed, floor)) {
    console.error(
      `check-oz-version: TOO OLD for ${name}\n` +
        `  CMTAT requires at least: ${floor.version} (declared "${required}")\n` +
        `  factory installed: ${installed}\n` +
        '  The factory must never sit below the version required by the pinned CMTAT submodule.'
    )
    failed = true
  } else if (semver.gt(installed, floor)) {
    console.warn(
      `check-oz-version: WARNING ${name} ${installed} is newer than CMTAT's pinned "${required}" ` +
        '(same major, so it compiles) - re-check when the submodule bumps its own pin.'
    )
    warned = true
  } else {
    console.log(`check-oz-version: OK ${name} ${installed} matches "${required}"`)
  }
}

if (!failed && warned) {
  console.warn('check-oz-version: passed with warnings.')
}

process.exit(failed ? 1 : 0)
