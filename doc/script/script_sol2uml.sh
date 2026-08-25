#!/bin/bash
# Generate the class diagrams referenced by doc/README.md with sol2uml.
# Output: doc/schema/sol2uml/ (committed, unlike the docOut/ scripts next to this one)
#
# One diagram per contract, interface or library, filtered with -b/-d 0 so the image stays a single
# class instead of the whole inheritance tree. Paths stay relative to the repository root: sol2uml
# prints the path it is given under the class name, so an absolute one would write machine-specific
# paths into the committed images.
#
# Rendering note: sol2uml's own PNG writer converts its SVG through a headless-Chromium helper
# (convert-svg-to-png) that is broken on current Node — it fails with
# "TypeError: Cannot read properties of undefined (reading 'html')". This script therefore asks
# sol2uml for Graphviz `dot` output and renders the PNG with `dot -Tpng` directly, which is the same
# renderer the Surya scripts beside this one already require. Set FORMAT=svg to skip Graphviz and let
# sol2uml emit SVG instead.
set -euo pipefail

cd "$(dirname "$0")/../../"
DIR_OUT="doc/schema/sol2uml"
FORMAT="${FORMAT:-png}"

# Test doubles under contracts/mocks/ are deliberately NOT diagrammed here: the documentation does not
# link them. (The Surya scripts beside this one do include them, on purpose.)

# "<image name>|<source file>|<contract name>"
DIAGRAMS=(
    # interfaces
    "ICMTATFactoryUML|contracts/interfaces/ICMTATFactory.sol|ICMTATFactory"
    "IERC8303UML|contracts/interfaces/IERC8303.sol|IERC8303"
    "IERC173UML|contracts/interfaces/IERC173.sol|IERC173"
    # libraries
    "FactoryErrorsUML|contracts/libraries/FactoryErrors.sol|FactoryErrors"
    # modules: core
    "CMTATFactoryInvariantUML|contracts/modules/core/CMTATFactoryInvariant.sol|CMTATFactoryInvariant"
    "ContractVersionUML|contracts/modules/core/ContractVersion.sol|ContractVersion"
    "CMTATFactoryRootUML|contracts/modules/core/CMTATFactoryRoot.sol|CMTATFactoryRoot"
    "CMTATFactoryBaseUML|contracts/modules/core/CMTATFactoryBase.sol|CMTATFactoryBase"
    # modules: proxy mechanism
    "CMTATTransparentFactoryBaseUML|contracts/modules/proxy/CMTATTransparentFactoryBase.sol|CMTATTransparentFactoryBase"
    "CMTATBeaconFactoryBaseUML|contracts/modules/proxy/CMTATBeaconFactoryBase.sol|CMTATBeaconFactoryBase"
    # modules: per-family deployment logic
    "CMTATUUPSFactoryBaseUML|contracts/modules/deployment/CMTATUUPSFactoryBase.sol|CMTATUUPSFactoryBase"
    "CMTATStandardTPFactoryBaseUML|contracts/modules/deployment/CMTATStandardTPFactoryBase.sol|CMTATStandardTPFactoryBase"
    "CMTATStandardBeaconFactoryBaseUML|contracts/modules/deployment/CMTATStandardBeaconFactoryBase.sol|CMTATStandardBeaconFactoryBase"
    "CMTATLightTPFactoryBaseUML|contracts/modules/deployment/CMTATLightTPFactoryBase.sol|CMTATLightTPFactoryBase"
    "CMTATLightBeaconFactoryBaseUML|contracts/modules/deployment/CMTATLightBeaconFactoryBase.sol|CMTATLightBeaconFactoryBase"
    # modules: access-control policies
    "CMTATFactoryAccessControlUML|contracts/modules/access/CMTATFactoryAccessControl.sol|CMTATFactoryAccessControl"
    "CMTATFactoryOwnable2StepUML|contracts/modules/access/CMTATFactoryOwnable2Step.sol|CMTATFactoryOwnable2Step"
    # deployables: role-based
    "CMTAT_UUPS_FACTORYUML|contracts/standard/CMTAT_UUPS_FACTORY.sol|CMTAT_UUPS_FACTORY"
    "CMTAT_TP_FACTORYUML|contracts/standard/CMTAT_TP_FACTORY.sol|CMTAT_TP_FACTORY"
    "CMTAT_BEACON_FACTORYUML|contracts/standard/CMTAT_BEACON_FACTORY.sol|CMTAT_BEACON_FACTORY"
    "CMTAT_LIGHT_TP_FACTORYUML|contracts/light/CMTAT_LIGHT_TP_FACTORY.sol|CMTAT_LIGHT_TP_FACTORY"
    "CMTAT_LIGHT_BEACON_FACTORYUML|contracts/light/CMTAT_LIGHT_BEACON_FACTORY.sol|CMTAT_LIGHT_BEACON_FACTORY"
    # deployables: single-owner
    "CMTAT_UUPS_FACTORY_Ownable2StepUML|contracts/ownable/CMTAT_UUPS_FACTORY_Ownable2Step.sol|CMTAT_UUPS_FACTORY_Ownable2Step"
    "CMTAT_TP_FACTORY_Ownable2StepUML|contracts/ownable/CMTAT_TP_FACTORY_Ownable2Step.sol|CMTAT_TP_FACTORY_Ownable2Step"
    "CMTAT_BEACON_FACTORY_Ownable2StepUML|contracts/ownable/CMTAT_BEACON_FACTORY_Ownable2Step.sol|CMTAT_BEACON_FACTORY_Ownable2Step"
    "CMTAT_LIGHT_TP_FACTORY_Ownable2StepUML|contracts/ownable/CMTAT_LIGHT_TP_FACTORY_Ownable2Step.sol|CMTAT_LIGHT_TP_FACTORY_Ownable2Step"
    "CMTAT_LIGHT_BEACON_FACTORY_Ownable2StepUML|contracts/ownable/CMTAT_LIGHT_BEACON_FACTORY_Ownable2Step.sol|CMTAT_LIGHT_BEACON_FACTORY_Ownable2Step"
)

# Wipe and replace, so a renamed or deleted contract does not leave a stale image behind.
rm -rf "$DIR_OUT"
mkdir -p "$DIR_OUT"
TMP_DOT="$(mktemp -d)"
trap 'rm -rf "$TMP_DOT"' EXIT

for entry in "${DIAGRAMS[@]}"; do
    IFS='|' read -r image source contract <<< "$entry"
    if [ ! -f "$source" ]; then
        echo "Missing source: $source" >&2
        exit 1
    fi
    if [ "$FORMAT" = "svg" ]; then
        npx sol2uml class "$source" -b "$contract" -d 0 -f svg -o "${DIR_OUT}/${image}.svg"
    else
        npx sol2uml class "$source" -b "$contract" -d 0 -f dot -o "${TMP_DOT}/${image}.dot"
        dot -Tpng "${TMP_DOT}/${image}.dot" -o "${DIR_OUT}/${image}.png"
    fi
done

echo "Generated ${#DIAGRAMS[@]} diagram(s) in ${DIR_OUT} (format: ${FORMAT})"
