#!/usr/bin/env bash
# Check that polish compiles against a facet checkout and record where facet is.
# polish's modules import each other (src/main.crush imports fmt, lexer, lint,
# which resolve from src/); facet is imported from FACET_DIR via -L. Nothing
# is concatenated any more.
#   FACET_DIR=/path/to/facet scripts/build.sh     (default ../facet; the directory
#                                                  that holds facet.crush)
# The resolved directory is recorded in build/facet.dir for scripts/polish.
set -euo pipefail
cd "$(dirname "$0")/.."
FACET_DIR="${FACET_DIR:-../facet}"
[ -f "$FACET_DIR/facet.crush" ] || { echo "build: facet.crush not found in $FACET_DIR (set FACET_DIR=)" >&2; exit 1; }
FACET_DIR="$(cd "$FACET_DIR" && pwd)"
CRUSHC="${CRUSHC:-crushc}"
mkdir -p build
# Compile check only (catches a missing import or a facet without the needed names).
"$CRUSHC" -L "$FACET_DIR" src/main.crush -o build/polish.cvm1 >/dev/null
printf '%s\n' "$FACET_DIR" > build/facet.dir
echo "polish compiles (facet from $FACET_DIR)"
