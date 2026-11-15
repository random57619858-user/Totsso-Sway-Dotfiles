#!/usr/bin/env bash

if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required but not installed. Aborting."
    exit 1
fi
if ! sudo -v; then
    fail "sudo is required. Aborting."
    exit 1
fi

info "Updating system..."
sudo apt update
sudo apt upgrade -y


info "Installing base packages from official repositories..."
sudo apt install -y \
    sway swaybg waybar kitty fish mako-notifier rofi \
    playerctl brightnessctl wl-clipboard grim slurp ffmpeg \
    pipewire wireplumber pipewire-audio \
    xdg-desktop-portal-wlr nwg-look nautilus cava xdg-desktop-portal-gtk \
    polkit-kde-agent-1 cliphist \
    xdg-user-dirs git unzip build-essential wget curl \
    fonts-noto-color-emoji \
    libwayland-dev wayland-protocols libxkbcommon-dev \
    libcairo2-dev meson ninja-build \
    hyprlock \
    libpam-ck-connector seatd firefox-esr
ok "Base packages installed."

if ! groups "$USER" | grep -q "\bvideo\b"; then
    info "Adding user to 'video' group (required for seatd)..."
    sudo usermod -aG video "$USER"
    warn "You need to log out and back in for group changes to take effect."
fi

info "Configuring Fish shell..."
if command -v fish >/dev/null 2>&1; then
    fish -c "set -U fish_greeting"
    ok "Fish greeting disabled."
else
    warn "Fish not found; skipping configuration."
fi

install_nerd_font
install_matugen
install_icons

info "Applying GTK settings..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
GTK_SETTINGS='[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Fluent-dark
gtk-font-name=Sans 10'
printf '%s\n' "$GTK_SETTINGS" > "$HOME/.config/gtk-3.0/settings.ini"
printf '%s\n' "$GTK_SETTINGS" > "$HOME/.config/gtk-4.0/settings.ini"

info "Configuring user services for Sway (PipeWire, etc.)..."
# Copiamos el script universal de servicios a la configuración de Sway
mkdir -p "$HOME/.config/sway/scripts"
if [ -f "$DOTFILES_DIR/scripts/start-services.sh" ]; then
    cp "$DOTFILES_DIR/scripts/start-services.sh" "$HOME/.config/sway/scripts/start-services.sh"
    chmod +x "$HOME/.config/sway/scripts/start-services.sh"
    
    SWAY_CONFIG="$HOME/.config/sway/config"
    if [ -f "$SWAY_CONFIG" ] && ! grep -q "start-services.sh" "$SWAY_CONFIG"; then
        echo "" >> "$SWAY_CONFIG"
        echo "exec_always --no-startup-id $HOME/.config/sway/scripts/start-services.sh" >> "$SWAY_CONFIG"
        ok "Universal service autostart added to Sway config."
    fi
else
    fail "start-services.sh not found in repo!"
fi

info "Configuring Sway autostart from TTY..."
PROFILE_FILE="$HOME/.bash_profile"
[ -f "$PROFILE_FILE" ] || PROFILE_FILE="$HOME/.profile"
if ! grep -q "exec sway" "$PROFILE_FILE"; then
    cat >> "$PROFILE_FILE" << 'EOF'

if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec sway
fi
EOF
    ok "Sway autostart configured in $PROFILE_FILE"
else
    ok "Sway autostart already configured."
fi

info "Setting up printer support (optional)..."
if confirm "Install printer support (CUPS + network discovery)?"; then
    sudo apt install -y cups avahi-daemon libnss-mdns system-config-printer
    warn "CUPS and Avahi will be started by Sway autostart."
    ok "Printer support packages installed."
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

setup_all_dotfiles
finish_install
