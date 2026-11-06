#!/bin/sh
#
# Replace the Tools section of README.md (between the tools:start and
# tools:end markers) with the output of scripts/readme-tools.zsh, run in the
# given image.
#
# usage: scripts/update-readme.sh IMAGE [README]

set -eu

image=$1
readme=${2:-README.md}
dir=$(cd "$(dirname "$0")" && pwd)

section=$(mktemp)
trap 'rm -f "$section" "$section.new"' EXIT

docker run --rm -v "$dir":/scripts:ro "$image" /scripts/readme-tools.zsh > "$section"

awk -v section="$section" '
  /<!-- tools:start -->/ { print; while ((getline line < section) > 0) print line; skip = 1; next }
  /<!-- tools:end -->/ { skip = 0 }
  !skip
' "$readme" > "$section.new"

if ! grep -q '<!-- tools:end -->' "$section.new"; then
  echo "error: $readme has no <!-- tools:start --> and <!-- tools:end --> markers" >&2
  exit 1
fi

mv "$section.new" "$readme"
