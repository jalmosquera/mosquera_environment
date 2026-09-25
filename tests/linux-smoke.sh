#!/usr/bin/env bash
# Run disposable Linux smoke tests with distro-specific container bootstrap.
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_arch() {
    docker run --rm --platform linux/arm64 --volume "$ROOT_DIR:/workspace:ro" archlinux:latest bash -ceu '
        pacman -Sy --noconfirm archlinux-keyring
        pacman -Syu --noconfirm --needed bash sudo shadow git curl ca-certificates
        useradd --create-home --shell /bin/bash mosquera
        printf "mosquera ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/mosquera
        mkdir /home/mosquera/environment
        cp -a /workspace/. /home/mosquera/environment/
        chown -R mosquera:mosquera /home/mosquera/environment
        su - mosquera -c 'HOME=/home/mosquera XDG_STATE_HOME=/home/mosquera/.local/state TERM=xterm-256color bash -c "cd /home/mosquera/environment && ./install workstation && ./doctor --profile workstation && ./update --dry-run"'
    '
}

run_ubuntu() {
    docker run --rm --platform linux/arm64 --volume "$ROOT_DIR:/workspace:ro" ubuntu:24.04 bash -ceu '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y bash sudo passwd git curl ca-certificates
        useradd --create-home --shell /bin/bash mosquera
        printf "mosquera ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/mosquera
        mkdir /home/mosquera/environment
        cp -a /workspace/. /home/mosquera/environment/
        chown -R mosquera:mosquera /home/mosquera/environment
        su - mosquera -c 'HOME=/home/mosquera XDG_STATE_HOME=/home/mosquera/.local/state TERM=xterm-256color bash -c "cd /home/mosquera/environment && ./install workstation && ./doctor --profile workstation && ./update --dry-run"'
    '
}

case "${1:-all}" in
    arch) run_arch ;;
    ubuntu) run_ubuntu ;;
    all) run_arch; run_ubuntu ;;
    *) printf 'Usage: %s [arch|ubuntu|all]\n' "$0" >&2; exit 1 ;;
esac
