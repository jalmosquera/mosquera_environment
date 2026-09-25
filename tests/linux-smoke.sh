#!/usr/bin/env bash
# Run disposable fresh-clone smoke tests with distro-specific bootstrap.
set -euo pipefail

readonly REPOSITORY_URL="${MOSQUERA_REPOSITORY_URL:-https://github.com/jalmosquera/mosquera_environment.git}"

run_smoke() {
    local image="$1" platform="$2" bootstrap="$3"
    docker run --rm --platform "$platform" --privileged --env REPOSITORY_URL="$REPOSITORY_URL" "$image" bash -ceu '
        eval "$1"
        useradd --create-home --shell /bin/bash mosquera
        printf "mosquera ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/mosquera
        runuser -u mosquera -- env HOME=/home/mosquera XDG_STATE_HOME=/home/mosquera/.local/state TERM=xterm-256color bash -ceu "
            git clone \"$REPOSITORY_URL\" /home/mosquera/environment
            cd /home/mosquera/environment
            export NVIM_APPNAME=mosquera-release-smoke
            ./install workstation
            git status --porcelain > /tmp/mosquera-git-status
            test ! -s /tmp/mosquera-git-status
            ./doctor --profile workstation
            ./update --dry-run
            ./install workstation
        "
    ' bash "$bootstrap"
}

run_arch() {
    run_smoke archlinux:latest linux/amd64 '
        pacman -Sy --noconfirm archlinux-keyring
        pacman -Syu --noconfirm --needed bash sudo shadow git curl ca-certificates
    '
}

run_ubuntu() {
    local platform="$1"
    run_smoke ubuntu:24.04 "$platform" '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y bash sudo passwd git curl ca-certificates
    '
}

case "${1:-all}" in
    arch) run_arch ;;
    ubuntu-arm64|ubuntu) run_ubuntu linux/arm64 ;;
    ubuntu-amd64) run_ubuntu linux/amd64 ;;
    all) run_arch; run_ubuntu linux/arm64; run_ubuntu linux/amd64 ;;
    *) printf 'Usage: %s [arch|ubuntu|ubuntu-arm64|ubuntu-amd64|all]\n' "$0" >&2; exit 1 ;;
esac
