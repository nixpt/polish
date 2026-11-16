# polish

A formatter and linter for [Crush](https://github.com/nixpt/crush-ast), written in
Crush: `polish fmt` (like `rustfmt`) and `polish lint` (growing into Crush's `clippy`).

**Status:** v0.1 - formatter plus token-level lints. Design: [docs/DESIGN.md](docs/DESIGN.md).
Its command line is built with [facet](https://github.com/nixpt/facet). Needs crush-ast >= 0.9.0.

## Usage

```sh
scripts/build.sh                                  # compile check + record the facet dir (FACET_DIR=, default ../facet)
scripts/polish fmt FILE...                        # rewrite files in place
scripts/polish fmt --check FILE...                # exit 1, list files that would change (CI)
scripts/polish fmt --stdout FILE                  # print the formatted file
scripts/polish lint FILE...                       # token lints
scripts/polish check FILE...                      # fmt --check + lint
    --message-format text|json                    # json = crush-diagnostics records, one per line
```

Nothing is concatenated. `src/main.crush` imports `fmt`, `lexer` and `lint`, which resolve
from `src/` (an importer's own directory comes first), and `import facet { facet_run, facet_fail }`.
Each module marks what it exports with `pub` (`polish_format`, `polish_lex`, `polish_lint`, `polish_run`);
the `__polish_*` helpers have no `pub`, so they are private to `src/` (files in `src/` still import
them from each other; `tests/` and other packages get the `pub` names only). Needs a toolchain with
`pub` (crush-ast after 0.11.2). `FACET_DIR` (the directory holding
`facet.crush`, default `../facet`) picks the facet checkout;
`scripts/polish` runs `src/main.crush` with `crush-run run -L <facet dir> --fs --fs-root / --env`
(needs a facet with required-positional support, facet >= 0.2.1; any path on the machine works; relative paths are taken from your working directory).

```
$ polish check messy.crush
messy.crush:1:1: error[P-UNFORMATTED]: file would be reformatted
  hint: run `polish fmt`
messy.crush:2:11: error[P-TRAILING-WS]: trailing whitespace
  hint: polish fmt removes it
$ polish fmt --check --message-format json messy.crush
{"code":"P-UNFORMATTED","level":"error","file":"messy.crush","line":1,"col":1,"message":"file would be reformatted","hint":"run `polish fmt`"}
```

## What `fmt` does

Whitespace only. Tokens are never added, removed, reordered or edited, so the formatted
program compiles to the same CASM (proved over crush-ast's corpus, `scripts/corpus.sh`).

- Indent 4 spaces per nesting level. Brackets opened on one line count as one level
  (`f(g(` then body = one level); a leading `}` / `)` / `]` closes before the line is indented.
  A line that continues an expression (previous line ends in a binary operator, or this one
  starts with `&& || + * / % == != |> .`) gets one extra level. Tabs become spaces.
- Trailing whitespace removed; CRLF becomes LF; one final newline; at most one blank line in a
  row; none at the start of the file, right after `{`, or right before a line starting with `}`.
- One space after `,` (none before it); none inside `( )` and `[ ]`; no space between a name
  and `(` (`fn add(`, `print(x)`; `if (x)` keeps its space).
- One space around `== != <= >= && || + - * / % =` when clearly binary (unary `-x`,
  ranges, lambda bars `|a|` stay as written).
- Comment text is kept (trailing blanks trimmed); comment lines take the indentation of
  the code around them; a trailing comment keeps its distance from the code (min. one space).
- Not touched: string contents, polyglot blocks (`@python { ... }`, `@lang[...] -> out { ... }`;
  copied byte for byte, using the real lexer's matching-brace rule), and every gap outside
  the rules above (`{`/`}` spacing, `:`, `<`/`>`, runs of spaces in the middle of a line).

A file that does not lex, or whose brackets do not balance, is reported
(`file:line:col`, codes `P-LEX` / `P-BRACKET`) and left unchanged.

## Lints

| code | level | what |
|---|---|---|
| `P-TRAILING-WS` | error | trailing whitespace (not inside strings / polyglot bodies) |
| `P-TAB` | error | tab used for indentation |
| `P-LINE-LEN` | warning | line longer than 100 columns |
| `P-BLANK-LINES` | error | more than one blank line in a row |
| `P-FINAL-NEWLINE` | error | missing or extra final newline |
| `P-UNFORMATTED` | error | `polish fmt` would change the file (`fmt --check`, `check`) |
| `P-LEX`, `P-BRACKET`, `P-IO` | error | file does not lex / brackets unbalanced / cannot be read |

## Exit status

`0` clean (warnings alone are clean) / `1` findings or files that would be reformatted /
`2` bad arguments (facet) / `70` internal error (the VM failed; message on stderr).

## Limits

- **Columns are characters** (Unicode scalars), the same as crushc's diagnostics; the
  100-column lint counts characters. (Crush's `len` and `str.index_of` count bytes, so polish
  indexes a character array instead: crush-ast #368.)
- Lines are never reflowed. Map literals in polish's own sources stay on one line
  (CRUSH-345), so `polish check` on them reports `P-LINE-LEN` warnings.
- Non-ASCII characters outside strings and comments are treated as identifier characters
  (the real lexer uses Unicode `is_alphanumeric`); an exotic Unicode space between tokens is
  therefore not recognised as whitespace. Text is still copied verbatim.
- No AST: no line wrapping, no spacing before `{`, no `<`/`>`/`:` spacing, no semantic lints
  yet (unused/shadowed variables, `== null` on optionals).
- Runtime errors in the VM cannot be caught from Crush (crush-ast #369); `scripts/polish`
  maps them to exit 70. Diagnostics go to stdout (no stderr in Crush yet, #370).
- Speed: about 0.1 s for a 12 KB file; the wrapper raises `--max-steps` (`POLISH_MAX_STEPS`).

## Tests

```sh
scripts/build.sh          # FACET_DIR=/path/to/facet to use another checkout
scripts/test.sh          # Crush self test (lexer, rules, idempotency, lints, tests/fmt goldens) + CLI tests
scripts/corpus.sh DIR... # CASM-identical + idempotent proof over a corpus of .crush files
```

## License

Licensed under either of [MIT](LICENSE-MIT) or [Apache License 2.0](LICENSE-APACHE) at
your option.
