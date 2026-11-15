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
    echo "│        UBUNTU SWAY DOTFILES INSTALLER            │"
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
    if [ "${ID:-}" != "ubuntu" ] && [ "${ID:-}" != "debian" ] && [[ "${ID_LIKE:-}" != *"ubuntu"* ]] && [[ "${ID_LIKE:-}" != *"debian"* ]]; then
        warn "Detected system: ${PRETTY_NAME:-unknown}"
        warn "This script is intended for Ubuntu/Debian."
        if ! confirm "Are you sure you want to continue anyway?"; then
            fail "Installation cancelled by user."
            exit 1
        fi
    else
        ok "Ubuntu/Debian detected: ${PRETTY_NAME:-unknown}"
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

info "Updating system..."
sudo apt update
sudo apt upgrade -y

info "Removing Snap completely..."
if confirm "Do you want to completely remove Snap and all its apps?"; then
    if command -v snap &>/dev/null; then
        snap list 2>/dev/null | awk 'NR>1 {print $1}' | while read -r pkg; do
            [ -n "$pkg" ] && sudo snap remove --purge "$pkg" || true
        done
    fi
    sudo apt purge snapd -y || true
    sudo apt autoremove --purge -y || true
    sudo apt-mark hold snapd 2>/dev/null || true
    rm -rf ~/snap 2>/dev/null || true
    sudo rm -rf /var/cache/snapd 2>/dev/null || true
    ok "Snap removed and pinned to prevent reinstallation."
else
    warn "Snap not removed."
fi

info "Installing Firefox from Mozilla PPA (deb, no Snap)..."
sudo snap remove firefox 2>/dev/null || true
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo bash -c 'cat > /etc/apt/preferences.d/firefox-no-snap << EOF
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF'
sudo apt update
sudo apt install -y firefox-esr
ok "Firefox ESR installed from PPA."

info "Installing base packages from official repositories..."
sudo apt install -y \
    sway swaybg waybar kitty fish rofi \
    playerctl brightnessctl wl-clipboard grim slurp ffmpeg \
    pipewire wireplumber pipewire-audio \
    xdg-desktop-portal-wlr nwg-look cava xdg-desktop-portal-gtk \
    polkit-kde-agent-1 cliphist \
    xdg-user-dirs git unzip build-essential wget curl \
    fonts-noto-color-emoji \
    libwayland-dev wayland-protocols libxkbcommon-dev \
    libcairo2-dev meson ninja-build \
    hyprlock

ok "Base packages installed."

info "Configuring Fish shell..."
if command -v fish >/dev/null 2>&1; then
    fish -c "set -U fish_greeting"
    ok "Fish greeting disabled."
else
    warn "Fish not found; skipping configuration."
fi


info "Installing JetBrainsMono Nerd Font..."
TMP_NF="$(mktemp_tracked)"
mkdir -p "$HOME/.local/share/fonts"
wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -O "$TMP_NF/JetBrainsMono.zip"
unzip -q -o "$TMP_NF/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/"
fc-cache -fv >/dev/null 2>&1 || true
ok "JetBrainsMono Nerd Font installed."

info "Installing Rust and Matugen..."
if ! command -v cargo >/dev/null 2>&1; then
    sudo apt install -y cargo
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

info "Enabling GDM..."
if systemctl is-enabled sddm 2>/dev/null || systemctl is-enabled lightdm 2>/dev/null; then
    warn "Another display manager is already enabled. GDM will not be enabled automatically."
else
    sudo apt install -y gdm3
    sudo systemctl enable gdm3
    ok "GDM enabled."
fi

info "Setting up printer support (optional)..."
if confirm "Install printer support (CUPS + network discovery)?"; then
    sudo apt install -y cups avahi-daemon libnss-mdns system-config-printer
    sudo systemctl enable --now cups.service avahi-daemon.service
    ok "Printer support ready."
fi

info "Installing Flatpak + Flathub (optional)..."
if confirm "Install Flatpak + Flathub?"; then
    sudo apt install -y flatpak
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
