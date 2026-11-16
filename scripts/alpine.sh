#!/usr/bin/env bash

if ! command -v doas >/dev/null 2>&1; then
    fail "doas is required but not installed. Aborting."
    exit 1
fi

sudo() { doas "$@"; }

if ! doas true; then
    fail "doas is required. Aborting."
    exit 1
fi

info "Migrating to official edge repositories..."
doas sed -i 's|https://[^/]*/alpine|https://dl-cdn.alpinelinux.org/alpine|g' /etc/apk/repositories
doas sed -i 's|v[0-9.]*/main|edge/main|g; s|v[0-9.]*/community|edge/community|g' /etc/apk/repositories

if ! grep -q "edge/testing" /etc/apk/repositories; then
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" | doas tee -a /etc/apk/repositories
fi

doas apk update
doas apk upgrade -a
ok "Official edge repositories enabled and system upgraded."

info "Forcing library updates for Wayland desktop..."
doas apk add --upgrade x265-libs gdk-pixbuf libinput-libs cairo libdrm
doas apk upgrade --available

info "Installing base packages from official repositories..."
doas apk add \
    sway swaybg waybar kitty fish rofi-wayland  \
    playerctl brightnessctl mako wl-clipboard grim coreutils slurp ffmpeg \
    pipewire wireplumber dbus dbus-openrc \
    xdg-desktop-portal-wlr nwg-look cava xdg-desktop-portal-gtk \
    cliphist \
    xdg-user-dirs polkit git bash unzip build-base wget curl \
    font-noto-emoji \
    wayland-dev wayland-protocols libxkbcommon-dev \
    cairo-dev meson ninja \
    seatd \
    hyprlock
ok "Base packages installed."

info "Enabling D-Bus system service..."
doas rc-update add dbus default
doas rc-service dbus start
ok "D-Bus enabled."

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

info "Configuring Sway autostart with seatd..."
doas adduser "$USER" seat 2>/dev/null || true

doas tee /usr/local/bin/start-sway > /dev/null << 'EOF'
#!/bin/sh
if [ ! -d "/run/user/$(id -u)" ]; then
    mkdir -p "/run/user/$(id -u)"
    chmod 0700 "/run/user/$(id -u)"
fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_SESSION_TYPE=wayland
export LIBSEAT_BACKEND=seatd
export XDG_CURRENT_DESKTOP=sway

if command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session sway
else
    if command -v dbus-launch >/dev/null 2>&1; then
        eval $(dbus-launch --sh-syntax)
    fi
    exec sway
fi
EOF
doas chmod +x /usr/local/bin/start-sway

if ! grep -q "start-sway" /etc/inittab; then
    doas cp /etc/inittab /etc/inittab.bak
    doas sed -i 's|^tty1::respawn:/sbin/getty.*|tty1::respawn:/usr/local/bin/start-sway|' /etc/inittab
    doas kill -HUP 1
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
    doas apk add cups cups-pdf avahi \
        gutenprint system-config-printer
    doas rc-update add cupsd default
    doas rc-update add avahi-daemon default
    doas rc-service cupsd start
    doas rc-service avahi-daemon start
    ok "Printer support ready."
fi

info "Installing Flatpak + Flathub (optional)..."
if confirm "Install Flatpak + Flathub?"; then
    doas apk add flatpak gnupg wget ca-certificates
    flatpak remote-delete flathub --user 2>/dev/null || true
    rm -rf ~/.local/share/flatpak/repo
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        ok "Flatpak and Flathub configured."
    else
        warn "Alpine's Flatpak is known to be unstable with GPG verification."
        warn "Continuing installation without Flatpak."
    fi
fi

if confirm "Install extra apps via Flatpak (Steam, Discord, VSCodium, OBS Studio)?"; then
    if flatpak remotes --user | grep -q "flathub"; then
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
    else
        warn "Flathub is not configured. Skipping Flatpak apps installation."
    fi
fi

setup_all_dotfiles
finish_install
