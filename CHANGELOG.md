# Changelog

All notable changes to polish. Format: [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- `capsule.toml`: polish as a crush-pkg package (entry `src/main.crush`, dependency facet at `../facet`,
  capabilities `env.get`, `fs.exists`, `fs.read`, `fs.write`). `crush-pkg check` passes and
  `crush-pkg run -- --version` prints `polish 0.1.0`. A registry can now see the facet dependency.

### Changed
- Visibility stage 2 (crush-ast#520): each module marks its exports with `pub`: `polish_format`
  (`src/fmt.crush`), `polish_lex` (`src/lexer.crush`), `polish_lint` (`src/lint.crush`) and
  `polish_run` (`src/main.crush`). Every other name, the `__polish_*` helpers included, is now
  private to `src/`. `crushc --list-exports --deny-legacy-visibility src` and the tests' compile
  gate (`crushc --check --deny-legacy-visibility -L src tests/polish_test.crush`) pass. polish now
  needs a toolchain that knows `pub` (crush-ast after 0.11.2). `src/main.crush` passes the gate
  only with a facet that has `pub` too; with an older facet the toolchain prints an `N-VIS01` note
  on stderr on every run, which `scripts/polish` reads as a runtime failure (exit 70 instead of 1).
- polish's own modules are now imported too, not concatenated: `src/fmt.crush` and
  `src/lint.crush` import `lexer`, `src/main.crush` imports `fmt`, `lexer` and `lint`,
  and `tests/polish_test.crush` imports what it tests (run with `-L src`).
  `scripts/build.sh` is now a `crushc` compile check that records `build/facet.dir`;
  `scripts/polish` runs `src/main.crush` directly. `build/polish.crush` is gone.
- facet is now `import`ed (`import facet { facet_run, facet_fail }`) instead of
  concatenated by `scripts/build.sh`. `scripts/polish` runs with `-L <facet dir>`.
  `FACET_DIR` (directory holding `facet.crush`, default `../facet`) replaces the
  `FACET=` file variable. polish's own `src/*.crush` files are still concatenated.
- Running `fmt`, `lint` or `check` with no files now prints facet's
  `missing required argument 'files'` instead of polish's `no files given`.
  The exit code is unchanged (2). Needs facet with the required-positional fix (facet#3).

### Removed
- polish's own empty-file-list checks in `src/main.crush` (facet enforces it now).
