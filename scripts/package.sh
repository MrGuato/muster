#!/usr/bin/env bash
# Check Muster/Muster.toc and build dist/Muster-<version>.zip.
#
#   bash scripts/package.sh            check and build
#   bash scripts/package.sh v0.1.0     also require the tag to match the .toc version
#
# The zip holds a single top-level Muster/ folder, ready to unzip into
# Interface/AddOns/.
set -euo pipefail
cd "$(dirname "$0")/.."

toc=Muster/Muster.toc
fail() { echo "package: $*" >&2; exit 1; }

version=$(sed -n 's/^## Version: *//p' "$toc" | tr -d '\r')
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "'## Version' in $toc is '$version', not x.y.z"
grep -q '^## Interface: 30300' "$toc" || fail "$toc must say '## Interface: 30300' (WoW 3.3.5a)"
grep -q '^## SavedVariables: MusterDB' "$toc" || fail "$toc lost its SavedVariables line"

code_version=$(sed -n 's/^M\.VERSION = "\(.*\)"$/\1/p' Muster/Core.lua)
[[ $code_version == "$version" ]] || fail "Core.lua says $code_version but $toc says $version"

if [[ $# -ge 1 ]]; then
    [[ $1 == "v$version" ]] || fail "tag $1 does not match .toc version $version"
fi

# Every file the .toc loads must exist, with the exact case WoW will ask for.
missing=0
while IFS= read -r line; do
    path=${line//\\//}
    if [[ ! -f "Muster/$path" ]]; then
        echo "package: $toc lists $line, which does not exist" >&2
        missing=1
    fi
done < <(grep -v '^##' "$toc" | tr -d '\r' | sed '/^[[:space:]]*$/d')
[[ $missing -eq 0 ]] || exit 1

for f in Muster/Bindings.xml Muster/Media/muster.tga; do
    [[ -f $f ]] || fail "$f is missing"
done

mkdir -p dist
zip="dist/Muster-$version.zip"
rm -f "$zip"
python3 - "$zip" <<'EOF'
import os, sys, zipfile
out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk("Muster"):
        dirs.sort()
        for name in sorted(files):
            if name.startswith("."):
                continue
            path = os.path.join(root, name)
            z.write(path, path)
EOF
echo "built $zip (version $version)"
