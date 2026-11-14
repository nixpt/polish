# Changelog

All notable changes to polish. Format: [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- `capsule.toml`: polish as a crush-pkg package (entry `src/main.crush`, dependency facet at `../facet`,
  capabilities `env.get`, `fs.exists`, `fs.read`, `fs.write`). `crush-pkg check` passes and
  `crush-pkg run -- --version` prints `polish 0.1.0`. A registry can now see the facet dependency.

### Changed
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
