#Version beta de soporte para Alpine linux: 

#!/usr/bin/env bash

if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required but not installed. Aborting."
    exit 1
fi

if ! sudo -v; then
    fail "sudo is required. Aborting."
    exit 1
fi

info "Enabling edge/testing and edge/community repositories..."
if ! grep -q "edge/testing" /etc/apk/repositories; then
    sudo sed -i '/^#.*edge\/community/s/^#//' /etc/apk/repositories
    sudo sed -i '/^#.*edge\/testing/s/^#//' /etc/apk/repositories
    if ! grep -q "edge/community" /etc/apk/repositories; then
        echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" | sudo tee -a /etc/apk/repositories
    fi
    if ! grep -q "edge/testing" /etc/apk/repositories; then
        echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" | sudo tee -a /etc/apk/repositories
    fi
    sudo apk update
fi
ok "Edge repositories enabled."

info "Updating system..."
sudo apk upgrade

info "Installing base packages from official repositories..."
sudo apk add \
    sway swaybg waybar kitty fish rofi-wayland  \
    playerctl brightnessctl mako wl-clipboard grim coreutils slurp ffmpeg \
    pipewire wireplumber \
    xdg-desktop-portal-wlr nwg-look cava xdg-desktop-portal-gtk \
    cliphist \
    xdg-user-dirs polkit-elogind git unzip build-base wget curl \
    font-noto-emoji \
    wayland-dev wayland-protocols libxkbcommon-dev \
    cairo-dev meson ninja \
    dbus-openrc elogind-openrc \
    hyprlock
ok "Base packages installed."

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

info "Configuring Sway autostart with D-Bus..."
# Creamos un script de arranque a nivel de sistema para asegurar las variables
sudo tee /usr/local/bin/start-sway > /dev/null << 'EOF'
#!/bin/sh
if [ ! -d "/run/user/$(id -u)" ]; then
    mkdir -p "/run/user/$(id -u)"
    chmod 0700 "/run/user/$(id -u)"
fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
exec dbus-run-session sway
EOF
sudo chmod +x /usr/local/bin/start-sway

if ! grep -q "start-sway" /etc/inittab; then
    sudo cp /etc/inittab /etc/inittab.bak
    sudo sed -i 's|^tty1::respawn:/sbin/getty.*|tty1::respawn:/usr/local/bin/start-sway|' /etc/inittab
    sudo kill -HUP 1
    ok "System-level Sway autostart configured in /etc/inittab"
else
    ok "System-level Sway autostart already configured."
fi

info "Configuring user services for Alpine (OpenRC)..."
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

info "Setting up printer support (optional)..."
if confirm "Install printer support (CUPS + network discovery)?"; then
    sudo apk add cups cups-pdf avahi \
        gutenprint system-config-printer
    sudo rc-update add cupsd default
    sudo rc-update add avahi-daemon default
    sudo rc-service cupsd start
    sudo rc-service avahi-daemon start
    ok "Printer support ready."
fi

info "Installing Flatpak + Flathub (optional)..."
if confirm "Install Flatpak + Flathub?"; then
    sudo apk add flatpak gnupg
    flatpak remote-delete flathub --user 2>/dev/null || true
    rm -rf ~/.local/share/flatpak/repo
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        ok "Flatpak and Flathub configured."
    else
        fail "Failed to configure Flathub. Check your network connection."
        exit 1
    fi
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
