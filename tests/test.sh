#!/usr/bin/env bash
###############################################################################
## Tests for hl. No dependencies beyond what hl itself needs.
##
##   ./tests/test.sh                 # uses ./hl
##   HL=/path/to/hl ./tests/test.sh  # test another copy
##   AWK=gawk ./tests/test.sh        # run the pipeline under a specific awk
###############################################################################
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
HL=${HL:-$HERE/../hl}

# Run hl under a chosen awk by putting a shim named "awk" first on PATH.
if [[ -n "${AWK:-}" ]]; then
    shim=$(mktemp -d)
    ln -s "$(command -v "$AWK")" "$shim/awk"
    PATH="$shim:$PATH"
    export PATH
    trap 'rm -rf "$shim"' EXIT
fi

# Fixed ANSI codes regardless of the terminal: TERM=dumb makes tput fail, so
# hl falls back to its built-in escape sequences.
export TERM=dumb
R=$'\033[0;31m'   # red
G=$'\033[0;32m'   # green
B=$'\033[0;34m'   # blue
BR=$'\033[1;31m'  # bright red
X=$'\033[0m'      # reset

pass=0
fail=0

check() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'FAIL: %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"
    fi
}

hl() { "$HL" "$@"; }

# --------------------------------------------------------------- matching

check "literal" "a ${R}car${X} b" "$(printf 'a car b\n' | hl car:red)"
check "every occurrence" "${R}x${X}-${R}x${X}" "$(printf 'x-x\n' | hl x:red)"
check "regex" "H${B}1${X} model" "$(printf 'H1 model\n' | hl '/[0-9]/:blue')"
check "regex interval" "at ${BR}09:30${X}" \
    "$(printf 'at 09:30\n' | hl '/[0-9]\{2\}:[0-9]\{2\}/:bred')"
check "literal dot is not a wildcard" "${R}a.b${X} axb" "$(printf 'a.b axb\n' | hl a.b:red)"
check "literal star and brackets" "${R}[*]${X}" "$(printf '[*]\n' | hl '[*]:red')"
check "literal caret and dollar" "${R}^\$${X}" "$(printf '^$\n' | hl '^$:red')"
check "literal backslash" "${R}a\\b${X}" "$(printf 'a\\b\n' | hl 'a\b:red')"
check "ampersand in pattern" "${G}a&b${X}" "$(printf 'a&b\n' | hl 'a&b:green')"
check "slash in literal" "${B}path/to${X}" "$(printf 'path/to\n' | hl 'path/to:blue')"
check "colon in pattern (last colon is the color)" "${R}12:30${X}" \
    "$(printf '12:30\n' | hl '12:30:red')"
check "alias color name" "${BR}x${X}" "$(printf 'x\n' | hl x:bright_red)"
check "no match passes the line through" "plain" "$(printf 'plain\n' | hl zzz:red)"
check "empty line" "" "$(printf '\n' | hl x:red)"
check "multiple lines" "${R}a${X}"$'\n'"b"$'\n'"${R}a${X}" "$(printf 'a\nb\na\n' | hl a:red)"

# ----------------------------------------------------- nesting and markers

check "nested highlight restores outer color" \
    "${R}ab${G}c${R}de${X}" "$(printf 'abcde\n' | hl abcde:red c:green)"
check "later pattern cannot match escape-code digits" \
    "${R}ERROR${X} ${B}3${X}" "$(printf 'ERROR 3\n' | hl ERROR:red '/[0-9]/:blue')"
check "marker bytes in input are scrubbed" "${R}inject${X}mex" \
    "$(printf 'inject\004me\020x\n' | hl inject:red)"
check "marker bytes in a pattern are scrubbed" "${R}ab${X}" \
    "$(printf 'ab\n' | hl $'a\004b:red')"
check "same color reused across patterns" "${R}a${X} ${R}b${X}" \
    "$(printf 'a b\n' | hl a:red b:red)"

# ---------------------------------------------------------- errors / usage

err=$(printf 'x\n' | hl x 2>&1)
check "missing color exits 2" "2" "$(printf 'x\n' | hl x >/dev/null 2>&1; echo $?)"
check "missing color message" "hl: missing color in 'x' (expected pattern:color)" "$err"
check "unknown color exits 2" "2" "$(printf 'x\n' | hl x:mauve >/dev/null 2>&1; echo $?)"
check "empty pattern exits 2" "2" "$(printf 'x\n' | hl :red >/dev/null 2>&1; echo $?)"
check "option without pattern exits 2" "2" "$(printf 'x\n' | hl -u >/dev/null 2>&1; echo $?)"
check "no args passes input through" "x" "$(printf 'x\n' | hl)"
check "-- ends options" "${R}-u${X}" "$(printf -- '-u\n' | hl -- -u:red)"
help=$(hl --help)
check "help starts with title" "hl - simple text highlighter (literal + regex support)" \
    "$(printf '%s\n' "$help" | sed -n '2p')"
check "help includes the last section" "yes" \
    "$(printf '%s\n' "$help" | grep -q '15 distinct colors' && echo yes || echo no)"

# ------------------------------------------------------------- streaming
#
# Feed one line through a FIFO that stays open (like `tail -f`) and see
# whether it comes out before hl is killed. With -u it must; without -u
# into a pipe it is allowed to buffer (that is the fast path).

streamed() { # extra hl args...
    # Portable (no `timeout`, which macOS lacks): run hl in the background
    # writing to a file, give it up to 2s to produce the line, then stop it.
    local fifo out pid _
    fifo=$(mktemp -u)
    out=$(mktemp)
    mkfifo "$fifo"
    exec 3<>"$fifo"
    printf 'live ERROR line\n' >&3
    "$HL" "$@" ERROR:red <&3 >"$out" 2>/dev/null &
    pid=$!
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        [[ -s "$out" ]] && break
        sleep 0.1
    done
    [[ -s "$out" ]] && echo yes || echo no
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    exec 3>&-
    rm -f "$fifo" "$out"
}

skipped=0
if sed -u -n '' </dev/null >/dev/null 2>&1 || sed -l -n '' </dev/null >/dev/null 2>&1; then
    can_stream=1
else
    # e.g. BusyBox sed: hl warns instead of streaming, by design.
    can_stream=0
    skipped=3
    printf 'SKIP: streaming tests (this sed has no -u or -l)\n'
    check "-u warns when sed cannot line-buffer" "yes" \
        "$(printf 'x\n' | "$HL" -u x:red 2>&1 >/dev/null | grep -q 'cannot line-buffer' && echo yes || echo no)"
fi

if [[ $can_stream -eq 1 ]]; then
    check "-u streams each line through a pipe" "yes" "$(streamed -u)"
    check "--line-buffered streams too" "yes" "$(streamed --line-buffered)"
fi

if [[ $can_stream -eq 1 ]] && command -v python3 >/dev/null 2>&1; then
    # stdout is a terminal: streaming must be automatic, no flag needed.
    tty_result=$(python3 - "$HL" <<'EOF'
import os, pty, select, subprocess, sys, time
master, slave = pty.openpty()
p = subprocess.Popen([sys.argv[1], "ERROR:red"], stdin=subprocess.PIPE,
                     stdout=slave, stderr=slave)
os.close(slave)
p.stdin.write(b"live ERROR line\n"); p.stdin.flush()
seen, start = b"", time.time()
while time.time() - start < 2 and b"line" not in seen:
    if select.select([master], [], [], 0.1)[0]:
        seen += os.read(master, 4096)
print("yes" if b"line" in seen else "no")
p.stdin.close(); p.wait()
EOF
)
    check "streams automatically on a terminal" "yes" "$tty_result"
fi

# ----------------------------------------------------------------- result

printf '%d passed, %d failed, %d skipped (awk: %s)\n' "$pass" "$fail" "$skipped" \
    "$(awk -W version </dev/null 2>&1 | head -n 1 || true)"
[[ $fail -eq 0 ]]
