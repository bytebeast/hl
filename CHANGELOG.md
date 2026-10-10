# Changelog

## Unreleased (2026-10-10)

### Bug Fixes

- **streaming**: `tail -f | hl` showed nothing until a 4-64 KB buffer filled,
  because `tr`, `sed` and `mawk` (the default awk on Debian/Ubuntu) all
  block-buffer through pipes. Input scrubbing now happens inside `sed`
  (`tr` has no line-buffered mode); `sed` runs with `-u`/`-l`, `mawk` with
  `-W interactive`, and awk flushes each line. This is automatic when output
  is a terminal, and available with `-u` for longer pipelines; bulk throughput
  is unchanged.
- **help**: `--help` printed a fixed line range of the script header; it now
  prints the whole header, however long.
- **README**: the "maximum 12 patterns" limit was removed from the code long
  ago (only 15 distinct colors cap it); the docs now say so.

### Features

- `-u` / `--line-buffered`, and `--` to end options
- warning when `-u` is requested but the system sed cannot line-buffer
  (BusyBox sed)
- test suite (`tests/test.sh`, plain Bash), verified with mawk, BusyBox awk,
  GNU sed and BusyBox sed
