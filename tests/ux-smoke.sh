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
