# polish — design

**One-liner:** a formatter and linter for Crush, written in Crush. `polish fmt` is
Crush's `rustfmt`; `polish lint` grows into its `clippy`.

## Decisions (captain, 2026-10-31)

- **Name:** `polish` — one tool, subcommands `fmt`, `lint`, `check`.
- **Approach:** self-hosted. A Crush lexer written in Crush produces a token stream
  that keeps comments, blank lines and exact positions. No toolchain change; like
  facet, it dogfoods the language, and crush-ast bugs found on the way are filed
  upstream.
- **v0.1 = formatter first**, plus a few token-level lints. Formatting has the
  clearest spec and is what crush-ast's CI asks for (CRUSH-148, a `fmt` gate).
- **CLI:** built on facet (`facet_run`), the same way any Crush program should be.
- **Output:** `--message-format json` emits crush-diagnostics' record shape
  (`code`, `level`, `file`, `line`, `col`, `message`, `hint`), so editors and CI read
  polish like `crushc` and `crush-run`.

## Guarantees (in priority order)

1. **Never change meaning.** The formatted program compiles to the same CASM as
   the input (`crushc --emit casm`), for every file in crush-ast's corpus. If polish
   can't prove it can format a region safely, it leaves that region alone.
2. **Never touch what isn't Crush:** string literal contents, comment text, and the
   bodies of polyglot blocks (`@python { … }`, `@javascript`, `@bash`, `@lang…`) are
   copied byte for byte.
3. **Idempotent:** `fmt(fmt(x)) == fmt(x)`.
4. **No surprises on bad input:** a file that doesn't lex is reported (file:line:col)
   and left unchanged.

## Formatter rules (v0.1, conservative)

- Indentation: 4 spaces per open `{` / `(` / `[` that ends its line; continuation
  lines inside an open bracket get one level.
- Trailing whitespace removed; tabs used for indentation become spaces.
- At most one blank line in a row; no blank lines right after `{` or before `}`.
- Exactly one final newline; no blank lines at the start of the file.
- Spacing (only where it can't change tokenization): one space after `,`; one
  space around `=` in `let`, and around binary operators `== != <= >= && || + - * /
  %` when they are clearly binary; none inside `(` `)` `[` `]`; `fn name(` with no
  space before `(`. Unary minus, ranges and lambda bars `|a|` keep their tokens
  adjacent.
- Line length: never reflowed in v0.1 (lint warns past 100 columns).
- Comments keep their text; their indentation follows the code they sit in.

Anything outside these rules is left as written.

## Lints (v0.1, token level)

| code | what |
|---|---|
| `P-TRAILING-WS` | trailing whitespace |
| `P-TAB` | tab used for indentation |
| `P-LINE-LEN` | line longer than 100 columns |
| `P-BLANK-LINES` | more than one blank line in a row |
| `P-FINAL-NEWLINE` | missing / extra final newline |
| `P-UNFORMATTED` | `polish fmt` would change the file (`polish check`) |

AST-level lints (unused or shadowed variables, unreachable code, `== null` on an
optional) come after v0.1, once the light structure pass exists.

## Layout

```
polish/
  lexer.crush      tokens with kind, text, line, col (comments, newlines, lang-block bodies as raw tokens)
  fmt.crush        token stream → formatted text
  lint.crush       token lints → diagnostic records
  main.crush       CLI on facet: polish fmt [--check] FILE…, polish lint FILE…, polish check FILE…
  tests/           lexer/fmt/lint checks; fmt golden files (tests/fmt/*.in.crush → *.out.crush)
  scripts/corpus.sh  format crush-ast's .crush corpus and prove CASM equality + idempotency
```

Crush has no source-level imports yet (crush-ast CRUSH-110, in progress), so until
it lands the files are concatenated by `scripts/build.sh`, exactly as facet is
consumed today.

## CLI

```
polish fmt FILE…            rewrite files in place
polish fmt --check FILE…    exit 1 and list files that would change (CI)
polish fmt --stdout FILE    print the formatted file
polish lint FILE…           token lints; exit 1 on any error-level finding
polish check FILE…          fmt --check + lint
  --message-format text|json
```

Exit status: 0 clean, 1 findings / would reformat, 2 bad arguments (facet), 70
internal error.
