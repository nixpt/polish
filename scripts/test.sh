#!/usr/bin/env bash
# polish self test (Crush) + CLI tests (bash).  Needs crush-run on PATH.
set -uo pipefail
cd "$(dirname "$0")/.."
CRUSH_RUN="${CRUSH_RUN:-crush-run}"
mkdir -p build
cat src/lexer.crush src/fmt.crush src/lint.crush tests/polish_test.crush > build/polish_test.crush
"$CRUSH_RUN" run --fs --max-steps 4000000000 build/polish_test.crush < /dev/null 2> build/test.err | tee build/test.out
rc=${PIPESTATUS[0]}
[ -s build/test.err ] && grep -v '^\[steps=' build/test.err >&2
fails=$(grep -c '^FAIL' build/test.out || true)
echo "unit: $(grep -c '^ok' build/test.out) ok, $fails failed (crush-run rc=$rc)"
[ "$rc" -eq 0 ] && [ "$fails" -eq 0 ] || exit 1
bash tests/cli.sh
