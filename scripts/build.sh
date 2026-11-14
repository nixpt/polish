#!/usr/bin/env bash
# Assemble build/polish.crush: an `import facet { facet_run, facet_fail }` line
# followed by polish's own sources, concatenated (they share __polish_* helpers).
# facet itself is imported, not concatenated; it is resolved at run time with
# `crush-run run -L <facet dir>` (see scripts/polish).
#   FACET_DIR=/path/to/facet scripts/build.sh     (default ../facet; the directory
#                                                  that holds facet.crush)
# The resolved directory is recorded in build/facet.dir for scripts/polish.
set -euo pipefail
cd "$(dirname "$0")/.."
FACET_DIR="${FACET_DIR:-../facet}"
[ -f "$FACET_DIR/facet.crush" ] || { echo "build: facet.crush not found in $FACET_DIR (set FACET_DIR=)" >&2; exit 1; }
FACET_DIR="$(cd "$FACET_DIR" && pwd)"
mkdir -p build
{
    echo 'import facet { facet_run, facet_fail }'
    cat src/lexer.crush src/fmt.crush src/lint.crush src/main.crush
} > build/polish.crush
printf '%s\n' "$FACET_DIR" > build/facet.dir
echo "built build/polish.crush (facet from $FACET_DIR)"
