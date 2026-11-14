# Changelog

All notable changes to polish. Format: [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Changed
- facet is now `import`ed (`import facet { facet_run, facet_fail }`) instead of
  concatenated by `scripts/build.sh`. `scripts/polish` runs with `-L <facet dir>`.
  `FACET_DIR` (directory holding `facet.crush`, default `../facet`) replaces the
  `FACET=` file variable. polish's own `src/*.crush` files are still concatenated.
- Running `fmt`, `lint` or `check` with no files now prints facet's
  `missing required argument 'files'` instead of polish's `no files given`.
  The exit code is unchanged (2). Needs facet with the required-positional fix (facet#3).

### Removed
- polish's own empty-file-list checks in `src/main.crush` (facet enforces it now).
