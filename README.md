<div align="center">

# hl

**A tiny, zero-dependency text highlighter for your terminal.**

Pipe anything into `hl` and color-highlight words, tokens, or regex patterns
with ANSI colors - great for `tail -f` logs, grepping, and general terminal
life.

[![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Shell Script](https://img.shields.io/badge/shell-script-89e051)](https://github.com/bytebeast/hl)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey)](#requirements)
[![Dependencies](https://img.shields.io/badge/dependencies-none-success)](#requirements)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/bytebeast/hl)](https://github.com/bytebeast/hl/commits)
[![GitHub issues](https://img.shields.io/github/issues/bytebeast/hl)](https://github.com/bytebeast/hl/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![GitHub stars](https://img.shields.io/github/stars/bytebeast/hl?style=social)](https://github.com/bytebeast/hl/stargazers)

</div>

---

## Preview

![curl-timings](images/hl-social-preview.png)

## Features

- **Literal or regex matching** - plain words by default, or wrap a pattern in
  `/.../` for `sed` BRE regex
- **Multiple patterns per call**, applied left to right
- **14 colors**, including bright variants with short aliases (`bred`, `bgreen`,
  ...)
- **Zero dependencies** - pure Bash + `sed` + `tput`/ANSI, nothing to install
- **Pipe-friendly** - reads stdin, writes stdout, plays nicely with `tail`,
  `grep`, `journalctl`, CI logs, anything text-based

## Requirements

- `bash` (4.0+)
- `sed`
- `tput` (optional - falls back to raw ANSI escape codes if unavailable)

No package manager, no runtime, no build step.

## Installation

**Quick install (curl):**

```bash
sudo curl -fsSL https://raw.githubusercontent.com/bytebeast/hl/main/hl -o /usr/local/bin/hl
sudo chmod +x /usr/local/bin/hl
```

**Clone and link:**

```bash
git clone https://github.com/bytebeast/hl.git
cd hl
chmod +x hl
ln -s "$(pwd)/hl" /usr/local/bin/hl   # or anywhere on your $PATH
```

Verify it's on your `PATH`:

```bash
hl <<< "installed correctly"
```

## Usage

```
echo "text" | hl pattern:color [pattern:color ...]
```

- **Literal match** (default): `hl word:red`
- **Regex match** (wrap the pattern in `/.../`, `sed` BRE syntax):
  `hl '/H[0-9]/':blue`

### Examples

```bash
# Highlight a single word
echo "The car is an H1 model" | hl car:red

# Highlight using a regex
echo "The car is an H1 model" | hl '/H[0-9]/':blue

# Stack multiple patterns
echo "The car is an H1 model" | hl car:red model:green '/H[0-9]/':blue

# Tail a log and flag errors/warnings in bright colors
tail -f app.log | hl ERROR:bred WARN:byellow INFO:cyan

# Works with anything piped over stdout
grep -i "timeout" server.log | hl timeout:bred
```

## Colors

| Name      | Alias | Name             | Alias      |
| --------- | ----- | ---------------- | ---------- |
| `black`   |       | `bright_red`     | `bred`     |
| `red`     |       | `bright_green`   | `bgreen`   |
| `green`   |       | `bright_yellow`  | `byellow`  |
| `yellow`  |       | `bright_blue`    | `bblue`    |
| `blue`    |       | `bright_magenta` | `bmagenta` |
| `magenta` |       | `bright_cyan`    | `bcyan`    |
| `cyan`    |       |                  |            |
| `white`   |       |                  |            |

## Notes

- Regex mode uses `sed` **BRE** syntax, not PCRE (no `\d`, `\w`, etc. - use
  POSIX character classes like `[0-9]` and `[[:alpha:]]`).
- Literal mode automatically escapes regex metacharacters, so special characters
  in plain words are matched safely.
- Patterns are applied sequentially, so later patterns can highlight inside text
  already touched by earlier ones.
- Colors gracefully degrade: if `tput` isn't available, `hl` falls back to raw
  ANSI escape sequences.

## Contributing

Issues and pull requests are welcome. If you're proposing a larger change,
please open an issue first to discuss what you'd like to change.

## License

Released under the [MIT License](LICENSE).

---

<div align="center">

If `hl` saved you some `grep -A -B` gymnastics or made your logs easier to read,
**please consider giving it a ⭐ star** - it helps other people find the project
and keeps it maintained.

</div>
