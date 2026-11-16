#!/usr/bin/env bash

ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
DIM="${ESC}[2m"
UNDERLINE="${ESC}[4m"

GREEN="${ESC}[38;5;114m"
CYAN="${ESC}[38;5;117m"
YELLOW="${ESC}[38;5;221m"
BLUE="${ESC}[38;5;111m"
RED="${ESC}[38;5;203m"
MAGENTA="${ESC}[38;5;176m"
GRAY="${ESC}[38;5;242m"
WHITE="${ESC}[38;5;255m"

banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo '   ███████╗██╗    ██╗ █████╗ ██╗   ██╗'
    echo '   ██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝'
    echo '   ███████╗██║ █╗ ██║███████║ ╚████╔╝ '
    echo '   ╚════██║██║███╗██║██╔══██║  ╚██╔╝  '
    echo '   ███████║╚███╔███╔╝██║  ██║   ██║   '
    echo '   ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   '
    echo -e "${RESET}"
    echo -e "${GRAY}   ──────────────────────────────────────────${RESET}"
    echo -e "   ${WHITE}${BOLD} Dotfiles Installer${RESET}"
    echo -e "   ${DIM}${GRAY}   Artix Linux${RESET}"
    echo -e "${GRAY}   ──────────────────────────────────────────${RESET}\n"
}

info()  { echo -e "\n ${BLUE}${BOLD} ${WHITE}${1}${RESET}"; }
ok()    { echo -e " ${GREEN} ${WHITE}${1}${RESET}"; }
warn()  { echo -e " ${YELLOW} ${WHITE}${1}${RESET}"; }
fail()  { echo -e " ${RED} ${WHITE}${1}${RESET}" >&2; }

step() {
    echo -e "\n${MAGENTA}${BOLD} ── ${1} ${RESET}${GRAY}────────────────────────────────────────${RESET}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

AUTO_INSTALL=false
if [[ "${1:-}" == "--yes" ]]; then AUTO_INSTALL=true; fi

confirm() {
    if [ "$AUTO_INSTALL" = true ]; then return 0; fi
    local msg="$1"
    local reply=""
    echo -ne "\n ${YELLOW}${BOLD} ${WHITE}${msg} ${GRAY}[y/N]${RESET} "
    read -r reply < /dev/tty || true
    echo ""
    [[ "${reply:-}" =~ ^[yYsS]$ ]]
}

CLEANUP_DIRS=()
cleanup() {
    local d
    for d in "${CLEANUP_DIRS[@]}"; do
        [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
    done
}
trap cleanup EXIT

mktemp_tracked() {
    local d
    d="$(mktemp -d)"
    CLEANUP_DIRS+=("$d")
    printf '%s' "$d"
}

BACKUP_ROOT="$DOTFILES_DIR/backup"
mkdir -p "$BACKUP_ROOT"

deploy() {
    local src="$1" dest="$2" name="$3"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if confirm "Back up your existing $name config?"; then
            mkdir -p "$BACKUP_ROOT/$name"
            if [ -L "$dest" ]; then cp -Pf "$dest" "$BACKUP_ROOT/$name/"
            elif [ -f "$dest" ]; then cp -f "$dest" "$BACKUP_ROOT/$name/"
            else cp -rf "$dest/." "$BACKUP_ROOT/$name/"; fi
            ok "Saved $name to $BACKUP_ROOT/$name"
        fi
    fi
    if [ ! -e "$src" ]; then warn "Source not found: $src (skipping $name)"; return 0; fi
    if [ -L "$dest" ]; then rm -f "$dest"; fi
    if [ -f "$src" ]; then mkdir -p "$(dirname "$dest")"; cp -f "$src" "$dest"
    elif [ -d "$src" ]; then mkdir -p "$dest"; cp -rf "$src/." "$dest/"; fi
}

install_nerd_font() {
    step "Installing Fonts"
    info "Downloading JetBrainsMono Nerd Font..."
    local TMP_NF="$(mktemp_tracked)"
    mkdir -p "$HOME/.local/share/fonts"
    
    if wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -O "$TMP_NF/JetBrainsMono.zip"; then
        if unzip -q -o "$TMP_NF/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/"; then
            fc-cache -fv >/dev/null 2>&1 || true
            ok "JetBrainsMono Nerd Font installed."
        else
            fail "Failed to unzip the font file. The download might be corrupted."
        fi
    else
        fail "Failed to download the font. Check your internet connection or the URL."
    fi
}

install_matugen() {
    step "Installing Matugen"
    if ! command -v cargo >/dev/null 2>&1; then
        info "Installing Rust compiler..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm rust
        elif command -v apk >/dev/null 2>&1; then
            sudo apk add rust cargo
        else
            fail "Unknown package manager. Cannot install Rust."
            exit 1
        fi
    fi
    
    if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    if ! command -v matugen >/dev/null 2>&1; then
        info "Compiling Matugen via Cargo (this WILL take several minutes)..."
        echo ""
        if cargo install matugen; then
            ok "Matugen installed."
        else
            fail "Failed to compile Matugen. Check the output above for details."
            exit 1
        fi
    else
        ok "Matugen is already installed."
    fi
}

install_icons() {
    step "Installing Icons"
    local TMP_ICONS="$(mktemp_tracked)"
    info "Cloning Fluent Icon Theme..."
    if git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git "$TMP_ICONS/Fluent-icon-theme" >/dev/null 2>&1; then
        info "Applying icons..."
        ( cd "$TMP_ICONS/Fluent-icon-theme" && chmod +x install.sh && ./install.sh -d "$HOME/.local/share/icons" >/dev/null 2>&1 )
        ok "Fluent icons installed."
    else
        warn "Failed to clone Fluent-icon-theme; skipping."
    fi
}

setup_nowplaying() {
    step "Rofi Nowplaying"
    local NOWPLAYING_DIR="$HOME/.config/rofi/nowplaying"
    
    if [ -d "$NOWPLAYING_DIR" ]; then
        info "Cleaning old installation..."
        rm -rf "$NOWPLAYING_DIR"
    fi
    mkdir -p "$NOWPLAYING_DIR"

    info "Cloning rofi-music-control..."
    if git clone https://github.com/Harsh-bin/rofi-music-control "$NOWPLAYING_DIR" >/dev/null 2>&1; then
        ok "Repository cloned successfully."
    else
        fail "Failed to clone rofi-music-control repository."
        exit 1
    fi

    if [ -f "$DOTFILES_DIR/rofi/nowplaying/nowplaying.rasi" ]; then
        info "Applying custom nowplaying.rasi..."
        cp -f "$DOTFILES_DIR/rofi/nowplaying/nowplaying.rasi" "$NOWPLAYING_DIR/nowplaying.rasi"
        ok "Custom nowplaying.rasi applied."
    fi

    if [ -f "$NOWPLAYING_DIR/nowplaying.sh" ]; then
        chmod +x "$NOWPLAYING_DIR/nowplaying.sh"
        ok "Permissions set for nowplaying.sh."
    else
        fail "nowplaying.sh not found after cloning. Installation cannot continue."
        exit 1
    fi

    touch "$NOWPLAYING_DIR/colors.rasi"
    ok "Rofi Nowplaying configured."
}

setup_all_dotfiles() {
    step "Deploying Dotfiles"
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then xdg-user-dirs-update; fi
    if command -v xdg-user-dir >/dev/null 2>&1; then IMG_DIR="$(xdg-user-dir PICTURES)"; else IMG_DIR="$HOME/Pictures"; fi
    if [ ! -d "$IMG_DIR" ] || [ "$IMG_DIR" = "$HOME/Pictures" ]; then mkdir -p "$IMG_DIR"; fi

    deploy "$DOTFILES_DIR/sway"    "$HOME/.config/sway"    "sway"
    deploy "$DOTFILES_DIR/waybar"  "$HOME/.config/waybar"  "waybar"
    deploy "$DOTFILES_DIR/kitty"   "$HOME/.config/kitty"   "kitty"
    deploy "$DOTFILES_DIR/rofi"    "$HOME/.config/rofi"    "rofi"
    deploy "$DOTFILES_DIR/hypr"    "$HOME/.config/hypr"    "hypr"
    deploy "$DOTFILES_DIR/matugen" "$HOME/.config/matugen" "matugen"
    deploy "$DOTFILES_DIR/mako"    "$HOME/.config/mako"    "mako"

    setup_nowplaying

    if [ -d "$DOTFILES_DIR/wallpapers" ]; then
        info "Copying wallpapers..."
        mkdir -p "$IMG_DIR"
        cp -rf "$DOTFILES_DIR/wallpapers/." "$IMG_DIR/"
        ok "Wallpapers copied to $IMG_DIR"
    fi

    step "Finalizing Permissions & Fixes"
    info "Applying executable permissions to scripts..."
    for d in sway waybar rofi hypr; do
        if [ -d "$HOME/.config/$d" ]; then
            find "$HOME/.config/$d" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
        fi
    done
    find "$DOTFILES_DIR" -maxdepth 3 -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

    info "Applying Sway Portal Fix..."
    if [ -f "$HOME/.config/sway/config" ]; then
        if ! grep -q "dbus-update-activation-environment" "$HOME/.config/sway/config"; then
            echo 'exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway' >> "$HOME/.config/sway/config"
            ok "Portal fix applied to Sway config."
        fi
    fi
}

finish_install() {
    echo -e "\n${GRAY}   ──────────────────────────────────────────${RESET}"
    echo -e "   ${GREEN}${BOLD}  Installation Complete!${RESET}"
    echo -e "   ${WHITE}You can now reboot and enjoy Sway.${RESET}"
    echo -e "${GRAY}   ──────────────────────────────────────────${RESET}"
    echo -e "   ${CYAN}Backups saved to: ${WHITE}${BOLD}$BACKUP_ROOT${RESET}"
    echo -e "   ${CYAN}Logs saved to:    ${WHITE}${BOLD}$DOTFILES_DIR/install.log${RESET}\n"
}
