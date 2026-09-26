#!/usr/bin/env bash
# Validate update policy using disposable local repositories.
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

create_repository() {
    local name="$1"
    git init --bare "$TMP_DIR/$name-origin.git" >/dev/null
    git clone "$TMP_DIR/$name-origin.git" "$TMP_DIR/$name-seed" >/dev/null
    git -C "$TMP_DIR/$name-seed" config user.email test@example.com
    git -C "$TMP_DIR/$name-seed" config user.name Test
    printf '%s\n' initial > "$TMP_DIR/$name-seed/state"
    git -C "$TMP_DIR/$name-seed" add state
    git -C "$TMP_DIR/$name-seed" commit -m initial >/dev/null
    git -C "$TMP_DIR/$name-seed" push -u origin HEAD:main >/dev/null
    git --git-dir="$TMP_DIR/$name-origin.git" symbolic-ref HEAD refs/heads/main
    git clone "$TMP_DIR/$name-origin.git" "$TMP_DIR/$name" >/dev/null
    git -C "$TMP_DIR/$name" config user.email test@example.com
    git -C "$TMP_DIR/$name" config user.name Test
}

run_update() {
    local expected="$1"
    shift
    if "$@" > "$TMP_DIR/update.log" 2>&1; then
        [[ "$expected" == success ]] || return 1
    else
        [[ "$expected" == failure ]] || return 1
    fi
}

create_repository environment
create_repository chats

export MOSQUERA_ENV_DIR="$TMP_DIR/environment"
export CHATSMANAGER_DIR="$TMP_DIR/chats"
export XDG_STATE_HOME="$TMP_DIR/state"
export UPDATE_SKIP_POST_ACTIONS=true

before_dry_run="$(git -C "$TMP_DIR/environment" rev-parse refs/remotes/origin/main)"
run_update success "$ROOT_DIR/update" --dry-run
after_dry_run="$(git -C "$TMP_DIR/environment" rev-parse refs/remotes/origin/main)"
[[ "$before_dry_run" == "$after_dry_run" ]]

printf '%s\n' dirty >> "$TMP_DIR/environment/state"
run_update failure "$ROOT_DIR/update"
git -C "$TMP_DIR/environment" restore state

printf '%s\n' ahead >> "$TMP_DIR/environment/state"
git -C "$TMP_DIR/environment" commit -am ahead >/dev/null
run_update failure "$ROOT_DIR/update"
git -C "$TMP_DIR/environment" reset --hard origin/main >/dev/null

printf '%s\n' remote > "$TMP_DIR/environment-seed/state"
git -C "$TMP_DIR/environment-seed" commit -am remote >/dev/null
git -C "$TMP_DIR/environment-seed" push >/dev/null
printf '%s\n' local >> "$TMP_DIR/environment/state"
git -C "$TMP_DIR/environment" commit -am local >/dev/null
run_update failure "$ROOT_DIR/update"
git -C "$TMP_DIR/environment" reset --hard origin/main >/dev/null

git -C "$TMP_DIR/environment" fetch origin >/dev/null
run_update success "$ROOT_DIR/update"
[[ "$(git -C "$TMP_DIR/environment" rev-parse HEAD)" == "$(git -C "$TMP_DIR/environment" rev-parse origin/main)" ]]
run_update success "$ROOT_DIR/update"
