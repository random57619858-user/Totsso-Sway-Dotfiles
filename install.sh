#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR
export SCRIPTS_DIR="$DOTFILES_DIR/scripts"

exec > >(tee -a "$DOTFILES_DIR/install.log") 2>&1

source "$SCRIPTS_DIR/common.sh"

trap 'fail "Error on line $LINENO. Check $DOTFILES_DIR/install.log for details."' ERR

banner

if [ "$(id -u)" -eq 0 ]; then
    fail "Do not run this script as root. Use your normal user (sudo is requested internally)."
    exit 1
fi

for cmd in git curl wget unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fail "Missing required command: $cmd"
        exit 1
    fi
done

OS_ID="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
fi

case "$OS_ID" in
    artix)
        ok "Artix Linux detected."
        source "$SCRIPTS_DIR/artix.sh"
        ;;
    *)
        fail "Detected system: ${PRETTY_NAME:-$OS_ID}"
        fail "This script is intended for Artix Linux only."
        exit 1
        ;;
esac
