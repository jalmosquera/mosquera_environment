#!/usr/bin/env bash
# Validate presentation behavior without requiring package installation.
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

assert_contains() {
    local file="$1" expected="$2"
    grep -Fq "$expected" "$file" || {
        printf 'Expected %s in %s\n' "$expected" "$file" >&2
        exit 1
    }
}

before_repo_state="$(git -C "$ROOT_DIR" status --porcelain)"
./install workstation --dry-run > "$TMP_DIR/install.log"
assert_contains "$TMP_DIR/install.log" 'MOSQUERA SOFT | install'
assert_contains "$TMP_DIR/install.log" 'DRY RUN: no changes will be made.'
assert_contains "$TMP_DIR/install.log" '[PROGRESS]'

after_repo_state="$(git -C "$ROOT_DIR" status --porcelain)"
[[ "$before_repo_state" == "$after_repo_state" ]]

./doctor --profile workstation > "$TMP_DIR/doctor.log"
assert_contains "$TMP_DIR/doctor.log" 'MOSQUERA SOFT | doctor'
assert_contains "$TMP_DIR/doctor.log" '[OK] Platform'

if ./update --dry-run > "$TMP_DIR/update.log"; then
    assert_contains "$TMP_DIR/update.log" 'MOSQUERA SOFT | update'
else
    assert_contains "$TMP_DIR/update.log" 'MOSQUERA SOFT | update'
fi

if bash -c 'source ./lib/presentation.sh; mosquera_ui_init test false false; mosquera_ui_command failure false' > "$TMP_DIR/failure.log" 2>&1; then
    printf 'Expected command failure to propagate.\n' >&2
    exit 1
fi
assert_contains "$TMP_DIR/failure.log" '[FAIL] failure'
assert_contains "$TMP_DIR/failure.log" 'Last output:'

printf 'q' | script -q "$TMP_DIR/tui-home.log" ./install >/dev/null 2>&1
assert_contains "$TMP_DIR/tui-home.log" 'Environment'
assert_contains "$TMP_DIR/tui-home.log" 'Seleccionar perfil'
assert_contains "$TMP_DIR/tui-home.log" 'Comprobar sistema'
assert_contains "$TMP_DIR/tui-home.log" '[?25h'

printf 'q' | script -q "$TMP_DIR/tui-wide.log" env TMUX='' COLUMNS=140 ./install >/dev/null 2>&1
assert_contains "$TMP_DIR/tui-wide.log" '███╗'
assert_contains "$TMP_DIR/tui-wide.log" 'Environment'

printf 'q' | script -q "$TMP_DIR/tui-narrow.log" env TMUX='' COLUMNS=80 ./install >/dev/null 2>&1
assert_contains "$TMP_DIR/tui-narrow.log" 'MOSQUERA SOFT'
if grep -Fq '███╗' "$TMP_DIR/tui-narrow.log"; then
    printf 'Expected narrow TUI to use the compact banner.\n' >&2
    exit 1
fi

printf 'p\033q' | script -q "$TMP_DIR/tui-profile.log" ./install >/dev/null 2>&1
assert_contains "$TMP_DIR/tui-profile.log" 'Seleccionar perfil'
assert_contains "$TMP_DIR/tui-profile.log" 'Estación completa de desarrollo'

printf 'q' | script -q "$TMP_DIR/tui-check.log" bash -c 'ROOT_DIR="$PWD"; source ./lib/tui.sh; mosquera_tui_automated_demo check' >/dev/null 2>&1
assert_contains "$TMP_DIR/tui-check.log" 'Comprobación del sistema'
assert_contains "$TMP_DIR/tui-check.log" 'Sistema listo.'

script -q "$TMP_DIR/tty.log" ./install workstation --dry-run >/dev/null 2>&1
assert_contains "$TMP_DIR/tty.log" 'MOSQUERA SOFT'
assert_contains "$TMP_DIR/tty.log" 'Overall'
assert_contains "$TMP_DIR/tty.log" '[?25l'
assert_contains "$TMP_DIR/tty.log" '[?25h'

COLUMNS=44 script -q "$TMP_DIR/narrow.log" ./install workstation --dry-run >/dev/null 2>&1
assert_contains "$TMP_DIR/narrow.log" 'MOSQUERA SOFT'

NO_COLOR=1 script -q "$TMP_DIR/no-color.log" ./install workstation --dry-run >/dev/null 2>&1
if grep -Eq $'\033\[[0-9;]*m' "$TMP_DIR/no-color.log"; then
    printf 'NO_COLOR output unexpectedly included color escapes.\n' >&2
    exit 1
fi
