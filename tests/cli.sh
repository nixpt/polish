#!/usr/bin/env bash
# CLI tests: exit codes, --check, --message-format json, in-place writes.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
P="$ROOT/scripts/polish"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
t() { # name, expected-rc, cmd...
    local name="$1" want="$2"; shift 2
    local out; out="$("$@" 2>&1)"; local rc=$?
    LAST="$out"
    if [ "$rc" -eq "$want" ]; then pass=$((pass+1)); echo "ok cli $name"; else fail=$((fail+1)); echo "FAIL cli $name (rc=$rc want $want)"; echo "$out" | head -5 | sed 's/^/    /'; fi
}
has() { # name, substring
    if grep -qF -- "$2" <<<"$LAST"; then pass=$((pass+1)); echo "ok cli $1"; else fail=$((fail+1)); echo "FAIL cli $1 (missing: $2)"; echo "$LAST" | head -5 | sed 's/^/    /'; fi
}

printf 'fn main() {\n    print("hi")\n}\n' > "$T/clean.crush"
printf 'fn main(){\n\tlet x=1  \n}' > "$T/messy.crush"
printf 'let s = "oops\n' > "$T/broken.crush"
printf 'let long = "%s"\n' "$(printf 'a%.0s' $(seq 1 100))" > "$T/long.crush"

t "fmt --check clean" 0 "$P" fmt --check "$T/clean.crush"
t "fmt --check messy" 1 "$P" fmt --check "$T/messy.crush"
has "check names the file" "messy.crush:1:1: error[P-UNFORMATTED]"
t "fmt --check leaves file" 0 grep -q "$(printf '\t')" "$T/messy.crush"
t "fmt --check json" 1 "$P" fmt --check --message-format json "$T/messy.crush"
has "json code" '"code":"P-UNFORMATTED"'
has "json level" '"level":"error"'
has "json line/col" '"line":1,"col":1'
t "json is valid" 0 bash -c "python3 -I -c 'import json,sys; [json.loads(l) for l in sys.stdin]' <<<\"\$1\"" _ "$LAST"
t "fmt --stdout" 0 "$P" fmt --stdout "$T/messy.crush"
has "stdout text" "    let x = 1"
t "fmt --stdout two files" 2 "$P" fmt --stdout "$T/clean.crush" "$T/messy.crush"
t "fmt in place" 0 "$P" fmt "$T/messy.crush"
t "in place result" 0 cmp -s "$T/messy.crush" <(printf 'fn main(){\n    let x = 1\n}\n')
t "fmt --check after fmt" 0 "$P" fmt --check "$T/messy.crush"
t "fmt broken file" 1 "$P" fmt "$T/broken.crush"
has "lex error position" "broken.crush:1:9: error[P-LEX]: unterminated string"
t "broken left unchanged" 0 cmp -s "$T/broken.crush" <(printf 'let s = "oops\n')
t "fmt missing file" 1 "$P" fmt "$T/nope.crush"
has "missing file code" "P-IO"
t "lint clean" 0 "$P" lint "$T/clean.crush"
t "lint warning only" 0 "$P" lint "$T/long.crush"
has "line-len warning" "warning[P-LINE-LEN]"
printf 'let x = 1  \n' > "$T/ws.crush"
t "lint error" 1 "$P" lint "$T/ws.crush"
has "trailing ws finding" "ws.crush:1:10: error[P-TRAILING-WS]"
t "lint json" 1 "$P" lint --message-format json "$T/ws.crush"
has "lint json hint" '"hint":"polish fmt removes it"'
t "lint broken" 1 "$P" lint "$T/broken.crush"
t "check clean" 0 "$P" check "$T/clean.crush"
t "check dirty" 1 "$P" check "$T/ws.crush"
has "check has unformatted" "P-UNFORMATTED"
has "check has lint" "P-TRAILING-WS"
t "bad subcommand" 2 "$P" bogus
t "no files" 2 "$P" fmt
t "bad message format" 2 "$P" lint --message-format xml "$T/clean.crush"
t "--check and --stdout" 2 "$P" fmt --check --stdout "$T/clean.crush"
t "version" 0 "$P" --version
has "version text" "polish 0.1.0"
t "help" 0 "$P" --help
t "relative path from other cwd" 0 bash -c "cd '$T' && '$P' fmt --check clean.crush"
t "dotdot path" 0 bash -c "mkdir -p '$T/d' && cd '$T/d' && '$P' fmt --check ../clean.crush"
t "several files" 1 "$P" fmt --check "$T/clean.crush" "$T/ws.crush"
# polish's own sources stay formatted
t "own sources formatted" 0 "$P" fmt --check src/lexer.crush src/fmt.crush src/lint.crush src/main.crush tests/polish_test.crush

echo "cli: $pass ok, $fail failed"
[ "$fail" -eq 0 ]
