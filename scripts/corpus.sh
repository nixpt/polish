#!/usr/bin/env bash
# Prove polish on a corpus of .crush files:
#   for each file that compiles (crushc --emit casm) before formatting,
#     * the formatted copy compiles to byte-identical CASM,
#     * formatting the formatted copy changes nothing (idempotent).
# usage: scripts/corpus.sh DIR...
# env: SCRATCH (default /tmp/polish-corpus), CRUSHC, POLISH
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CRUSHC="${CRUSHC:-crushc}"
POLISH="${POLISH:-$HERE/scripts/polish}"
SCRATCH="${SCRATCH:-/tmp/polish-corpus}"
[ $# -gt 0 ] || { echo "usage: corpus.sh DIR..." >&2; exit 2; }
rm -rf "$SCRATCH/fmt" "$SCRATCH/casm"; mkdir -p "$SCRATCH/fmt" "$SCRATCH/casm"
files=0 changed=0 identical=0 idem=0 skipped=0 bad=0
while IFS= read -r f; do
    files=$((files+1))
    id="$(printf '%s' "$f" | md5sum | cut -c1-12)"
    copy="$SCRATCH/fmt/$id.crush"
    cp "$f" "$copy"
    before="$SCRATCH/casm/$id.before"
    if ! "$CRUSHC" --emit casm "$f" > "$before" 2>/dev/null < /dev/null; then
        skipped=$((skipped+1)); echo "SKIP (does not compile before): $f"; continue
    fi
    if ! "$POLISH" fmt "$copy" > "$SCRATCH/casm/$id.out" 2>&1; then
        bad=$((bad+1)); echo "FAIL (polish fmt): $f"; sed 's/^/    /' "$SCRATCH/casm/$id.out" | head -5; continue
    fi
    cmp -s "$f" "$copy" || changed=$((changed+1))
    if ! "$CRUSHC" --emit casm "$copy" > "$SCRATCH/casm/$id.after" 2>/dev/null < /dev/null; then
        bad=$((bad+1)); echo "FAIL (formatted file no longer compiles): $f"; continue
    fi
    if cmp -s "$before" "$SCRATCH/casm/$id.after"; then identical=$((identical+1)); else bad=$((bad+1)); echo "FAIL (CASM differs): $f"; fi
    cp "$copy" "$copy.1"
    "$POLISH" fmt "$copy" > /dev/null 2>&1
    if cmp -s "$copy" "$copy.1"; then idem=$((idem+1)); else bad=$((bad+1)); echo "FAIL (not idempotent): $f"; fi
done < <(for d in "$@"; do find "$d" -name '*.crush' -type f; done | sort)
echo "files=$files formatted-changed=$changed casm-identical=$identical idempotent=$idem skipped=$skipped failures=$bad"
[ "$bad" -eq 0 ]
