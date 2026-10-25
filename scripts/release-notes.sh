#!/usr/bin/env bash
# Print one version's section of CHANGELOG.md, for the GitHub release notes.
#   bash scripts/release-notes.sh 0.1.0
set -euo pipefail
cd "$(dirname "$0")/.."
version=${1:?usage: release-notes.sh <version>}
notes=$(awk -v v="$version" '
    index($0, "## [" v "]") == 1 { on = 1; next }
    on && /^## \[/ { exit }
    on && /^\[[^]]+\]: / { next }
    on { print }' CHANGELOG.md)
if [[ -z ${notes//[[:space:]]/} ]]; then
    echo "release-notes: CHANGELOG.md has no section for $version" >&2
    exit 1
fi
printf '%s\n\n%s\n' "$notes" "Install: unzip \`Muster-$version.zip\` into \`World of Warcraft/Interface/AddOns/\`. Docs: https://mrguato.github.io/muster/"
