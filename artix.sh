#!/usr/bin/env bash
set -euo pipefail

ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
GREEN="${ESC}[32m"
CYAN="${ESC}[36m"
YELLOW="${ESC}[33m"
BLUE="${ESC}[34m"
RED="${ESC}[31m"

banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "┌──────────────────────────────────────────────────┐"
    echo "│        ARTIX LINUX SWAY DOTFILES INSTALLER       │"
    echo "└──────────────────────────────────────────────────┘"
    echo -e "${RESET}"
}

info()  { echo -e "\n${BLUE}${BOLD}==> ${1}${RESET}"; }
ok()    { echo -e "${GREEN}✔ ${1}${RESET}"; }
warn()  { echo -e "${YELLOW}⚠ ${1}${RESET}"; }
fail()  { echo -e "${RED}✖ ${1}${RESET}" >&2; }

AUTO_INSTALL=false
if [[ "${1:-}" == "--yes" ]]; then AUTO_INSTALL=true; fi

confirm() {
    if [ "$AUTO_INSTALL" = true ]; then return 0; fi
    local msg="$1"
    local reply=""
    read -p "$msg (y/N): " reply < /dev/tty || true
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

banner

if [ "$(id -u)" -eq 0 ]; then
    fail "Do not run this script as root. Use your normal user (sudo is requested internally)."
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "${ID:-}" != "artix" ]; then
        warn "Detected system: ${PRETTY_NAME:-unknown}"
        warn "This script is intended for Artix Linux only."
        if ! confirm "Are you sure you want to continue anyway?"; then
            fail "Installation cancelled by user."
            exit 1
        fi
    else
        ok "Artix Linux detected: ${PRETTY_NAME:-unknown}"
    fi
else
    fail "Could not detect OS (/etc/os-release not found)."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required but not installed. Aborting."
    exit 1
fi

if ! sudo -v; then
    fail "sudo is required. Aborting."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$DOTFILES_DIR/backup"
mkdir -p "$BACKUP_ROOT"

info "Enabling multilib repository..."
if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    if confirm "Enable multilib repository?"; then
        sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
        ok "Multilib repository enabled."
        sudo pacman -Sy
    fi
else
    ok "Multilib repository is already enabled."
fi

info "Updating system..."
sudo pacman -Syu --noconfirm

info "Checking/Installing yay (AUR helper)..."
if ! command -v yay >/dev/null 2>&1; then
    info "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    TMP_YAY="$(mktemp_tracked)"
    git clone https://aur.archlinux.org/yay.git "$TMP_YAY/yay"
    ( cd "$TMP_YAY/yay" && makepkg -si --noconfirm )
    ok "yay installed."
else
    ok "yay is already installed."
fi

info "Installing base packages from official repositories..."
sudo pacman -S --needed --noconfirm \
    sway swaybg waybar kitty rofi \
    playerctl brightnessctl wl-clipboard grim slurp ffmpeg \
    pipewire-openrc wireplumber-openrc pipewire-pulse-openrc \
    xdg-desktop-portal-wlr cava nwg-look xdg-desktop-portal-gtk \
    polkit-kde-agent cliphist \
    xdg-user-dirs git unzip base-devel wget curl \
    wayland wayland-protocols libxkbcommon \
    cairo meson elogind ninja \
    hyprlock

ok "Base packages installed."

info "Installing JetBrainsMono Nerd Font..."
TMP_NF="$(mktemp_tracked)"
mkdir -p "$HOME/.local/share/fonts"
wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -O "$TMP_NF/JetBrainsMono.zip"
unzip -q -o "$TMP_NF/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/"
fc-cache -fv >/dev/null 2>&1 || true
ok "JetBrainsMono Nerd Font installed."

info "Installing Rust and Matugen..."
if ! command -v cargo >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm rust
fi

if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if ! command -v matugen >/dev/null 2>&1; then
    cargo install matugen
    ok "Matugen installed via cargo."
else
    ok "Matugen is already installed."
fi

info "Installing Fluent icon theme..."
TMP_ICONS="$(mktemp_tracked)"
if git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git "$TMP_ICONS/Fluent-icon-theme"; then
    ( cd "$TMP_ICONS/Fluent-icon-theme" && chmod +x install.sh && ./install.sh -d "$HOME/.local/share/icons" )
    ok "Icons installed."
else
    warn "Failed to clone Fluent-icon-theme; skipping."
fi

info "Applying GTK settings..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
GTK_SETTINGS='[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Fluent-dark
gtk-font-name=Sans 10'
printf '%s\n' "$GTK_SETTINGS" > "$HOME/.config/gtk-3.0/settings.ini"
printf '%s\n' "$GTK_SETTINGS" > "$HOME/.config/gtk-4.0/settings.ini"

info "Configuring Sway autostart with D-Bus..."
PROFILE_FILE="$HOME/.bash_profile"
[ -f "$PROFILE_FILE" ] || PROFILE_FILE="$HOME/.profile"

if ! grep -q "dbus-run-session sway" "$PROFILE_FILE"; then
    cat >> "$PROFILE_FILE" << 'EOF'

if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec dbus-run-session sway
fi
EOF
    ok "Sway autostart with D-Bus configured in $PROFILE_FILE"
else
    ok "Sway autostart already configured."
fi

info "Enabling PipeWire user services (OpenRC)..."
if ! command -v rc-update >/dev/null 2>&1; then
    warn "OpenRC not found. Skipping user service configuration."
else
    mkdir -p "$HOME/.config/rc/init.d"
    if [ ! -f "$HOME/.config/rc/init.d/pipewire" ]; then
        cat > "$HOME/.config/rc/init.d/pipewire" << 'EOF'
#!/usr/bin/openrc-run
supervisor="supervise-daemon"
description="Low-latency audio/video router and processor"
command="/usr/bin/pipewire"
EOF
    fi
    if [ ! -f "$HOME/.config/rc/init.d/pipewire-pulse" ]; then
        cat > "$HOME/.config/rc/init.d/pipewire-pulse" << 'EOF'
#!/usr/bin/openrc-run
supervisor="supervise-daemon"
description="PipeWire PulseAudio replacement"
command="/usr/bin/pipewire-pulse"
depend() { need pipewire; }
EOF
    fi
    if [ ! -f "$HOME/.config/rc/init.d/wireplumber" ]; then
        cat > "$HOME/.config/rc/init.d/wireplumber" << 'EOF'
#!/usr/bin/openrc-run
supervisor="supervise-daemon"
description="PipeWire session manager"
command="/usr/bin/wireplumber"
depend() { need pipewire; after pipewire-pulse; }
EOF
    fi
    chmod +x "$HOME/.config/rc/init.d/"*

    rc-update --user add pipewire default 2>/dev/null || rc-update -U add pipewire default
    rc-update --user add pipewire-pulse default 2>/dev/null || rc-update -U add pipewire-pulse default
    rc-update --user add wireplumber default 2>/dev/null || rc-update -U add wireplumber default

    ok "PipeWire user services enabled."
fi

info "Ensuring elogind is enabled..."
sudo rc-update add elogind boot 2>/dev/null || true
sudo rc-service elogind start 2>/dev/null || true
ok "elogind enabled."

info "Setting up printer support (optional)..."
if confirm "Install printer support (CUPS + network discovery)?"; then
    sudo pacman -S --needed --noconfirm cups-openrc cups-pdf avahi-openrc nss-mdns \
        gutenprint foomatic-db foomatic-db-ppds system-config-printer
    sudo rc-update add cupsd default
    sudo rc-update add avahi-daemon default
    sudo rc-service cupsd start
    sudo rc-service avahi-daemon start
    ok "Printer support ready."
fi

info "Installing Flatpak + Flathub (optional)..."
if confirm "Install Flatpak + Flathub?"; then
    sudo pacman -S --needed --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    ok "Flatpak and Flathub configured."
fi

if confirm "Install extra apps via Flatpak (Steam, Discord, VSCodium, OBS Studio)?"; then
    for app in \
        com.valvesoftware.Steam \
        com.discordapp.Discord \
        com.vscodium.codium \
        com.obsproject.Studio \
        org.onlyoffice.desktopeditors    
    do
        info "Installing $app..."
        flatpak install -y --noninteractive flathub "$app"
    done
    ok "Extra apps installed via Flatpak."
fi

info "Setting up user directories..."
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
fi

if command -v xdg-user-dir >/dev/null 2>&1; then
    IMG_DIR="$(xdg-user-dir PICTURES)"
else
    IMG_DIR="$HOME/Pictures"
fi

if [ ! -d "$IMG_DIR" ] || [ "$IMG_DIR" = "$HOME/Pictures" ]; then
    mkdir -p "$IMG_DIR"
fi

info "Deploying dotfiles..."
deploy() {
    local src="$1" dest="$2" name="$3"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if confirm "Back up your existing $name config?"; then
            mkdir -p "$BACKUP_ROOT/$name"
            if [ -L "$dest" ]; then
                cp -Pf "$dest" "$BACKUP_ROOT/$name/"
            elif [ -f "$dest" ]; then
                cp -f "$dest" "$BACKUP_ROOT/$name/"
            else
                cp -rf "$dest/." "$BACKUP_ROOT/$name/"
            fi
            ok "Saved $name to $BACKUP_ROOT/$name"
        fi
    fi
    if [ ! -e "$src" ]; then
        warn "Source not found: $src (skipping $name)"
        return 0
    fi
    if [ -L "$dest" ]; then rm -f "$dest"; fi
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp -f "$src" "$dest"
    elif [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -rf "$src/." "$dest/"
    fi
}

deploy "$DOTFILES_DIR/sway"    "$HOME/.config/sway"    "sway"
deploy "$DOTFILES_DIR/waybar"  "$HOME/.config/waybar"  "waybar"
deploy "$DOTFILES_DIR/kitty"   "$HOME/.config/kitty"   "kitty"
deploy "$DOTFILES_DIR/rofi"    "$HOME/.config/rofi"    "rofi"
deploy "$DOTFILES_DIR/hypr"    "$HOME/.config/hypr"    "hypr"
deploy "$DOTFILES_DIR/matugen" "$HOME/.config/matugen" "matugen"

if [ -d "$DOTFILES_DIR/wallpapers" ]; then
    mkdir -p "$IMG_DIR"
    cp -rf "$DOTFILES_DIR/wallpapers/." "$IMG_DIR/"
    ok "Wallpapers copied to $IMG_DIR"
else
    warn "No wallpapers directory in repo, skipping."
fi

info "Fixing script permissions..."
for d in sway waybar rofi hypr; do
    if [ -d "$HOME/.config/$d" ]; then
        find "$HOME/.config/$d" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    fi
done
find "$DOTFILES_DIR" -maxdepth 3 -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

info "Applying Sway Portal Fix..."
if ! grep -q "dbus-update-activation-environment" "$HOME/.config/sway/config"; then
    echo 'exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway' >> "$HOME/.config/sway/config"
    ok "Portal fix applied to Sway config."
fi

echo -e "\n${GREEN}${BOLD}┌──────────────────────────────────────────────────┐"
echo "│              All done! Reboot when ready :)        │"
echo "└──────────────────────────────────────────────────┘${RESET}\n"
echo -e "${CYAN}Backups saved to: ${BOLD}$BACKUP_ROOT${RESET}\n"
