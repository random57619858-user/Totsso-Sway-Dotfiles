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
    devuan)
        ok "Devuan detected."
        source "$SCRIPTS_DIR/devuan.sh"
        ;;
    debian)
        ok "Debian detected."
        warn "Debian is supported via the Devuan installer. Some packages may differ."
        source "$SCRIPTS_DIR/devuan.sh"
        ;;
    *)
        warn "Detected system: ${PRETTY_NAME:-$OS_ID}"
        warn "This script is intended for Artix Linux or Devuan."
        if confirm "Are you sure you want to continue anyway?"; then
            source "$SCRIPTS_DIR/devuan.sh"
        else
            fail "Installation cancelled by user."
            exit 1
        fi
        ;;
esac
