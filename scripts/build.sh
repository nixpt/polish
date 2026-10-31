#!/usr/bin/env bash
# Concatenate facet + polish's sources into build/polish.crush (Crush has no
# source-level imports yet, CRUSH-110).
#   FACET=/path/to/facet.crush scripts/build.sh      (default ../facet/facet.crush)
set -euo pipefail
cd "$(dirname "$0")/.."
FACET="${FACET:-../facet/facet.crush}"
[ -f "$FACET" ] || { echo "build: facet not found at $FACET (set FACET=)" >&2; exit 1; }
mkdir -p build
cat "$FACET" src/lexer.crush src/fmt.crush src/lint.crush src/main.crush > build/polish.crush
echo "built build/polish.crush"
