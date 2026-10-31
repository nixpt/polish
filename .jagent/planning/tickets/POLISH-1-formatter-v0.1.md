# POLISH-1 - formatter v0.1 (and first token lints), written in Crush

| Field | Value |
|-------|-------|
| **ID** | POLISH-1 |
| **Status** | Done |
| **Branch** | `agent/nova/POLISH-1` |

## Scope

`polish fmt|lint|check` per docs/DESIGN.md: a Crush lexer that keeps comments, whitespace
and positions; a whitespace-only formatter; six token lints; facet CLI with
`--check`, `--stdout`, `--message-format json`; exit codes 0/1/2/70.

## Resolution

Done. Files: `src/{lexer,fmt,lint,main}.crush`, `scripts/{build,polish,test,corpus}.sh`,
`tests/polish_test.crush`, `tests/cli.sh`, `tests/fmt/*.{in,out}.crush`.

Verified on the crush-ast v0.9.0 release binaries:

- `scripts/test.sh`: 147 unit checks + 43 CLI checks, all passing.
- `scripts/corpus.sh` over crush-ast `examples/` (63 files): 11 changed by the formatter,
  53 compile before and after to byte-identical CASM, 53 idempotent, 10 skipped because
  they do not compile on 0.9.0 (unsupported `semantic_switch` CRUSH-265, `str` type
  error, a comment inside braces). 0 failures. Over every `.crush` file in crush-ast
  (131): 25 changed, 108 CASM-identical, 108 idempotent, 23 skipped, 0 failures.
- `polish fmt --check` over polish's own sources is clean.

Decisions where DESIGN.md was silent (also in README): columns count characters;
`P-LINE-LEN` is a warning and the other whitespace lints are errors; `{`/`}` spacing, `:`,
`<`/`>` and mid-line space runs are left as written; continuation lines get one extra
indent level; unbalanced brackets are a reported error (file unchanged); unreadable
file is `P-IO` (exit 1); empty / whitespace-only files format to empty.

Upstream issues filed while building: nixpt/crush-ast #367 (regex.match unparseable),
#368 (len/index_of bytes vs char_at/slices chars), #369 (try/catch ignores runtime errors),
#370 (no array pop, io.eprint, str.ord/chr).

Not done: AST-level lints; line wrapping; space before block `{`.
