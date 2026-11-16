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
doas tee /etc/apk/repositories > /dev/null << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

doas apk update
doas apk upgrade -a
ok "Official edge repositories enabled and system upgraded."

info "Forcing library updates for Wayland desktop..."
doas apk add --upgrade x265-libs gdk-pixbuf libinput-libs cairo libdrm
doas apk upgrade --available
ok "Core Wayland libraries updated."

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
    seatd greetd greetd-tuigreet \
    eudev xkeyboard-config \
    hyprlock
ok "Base packages installed."

info "Enabling system services (D-Bus, Udev)..."
doas rc-update add dbus default
doas rc-service dbus start

doas rc-update add udev default
doas rc-service udev start
doas rc-service udev-trigger start
ok "D-Bus and Udev enabled."

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

info "Deploying dotfiles BEFORE configuring display manager..."

setup_all_dotfiles

info "Configuring greetd display manager..."
doas adduser greetd seat 2>/dev/null || true
doas rc-update add seatd default 2>/dev/null || true
doas rc-service seatd start 2>/dev/null || true

if [ -f "$DOTFILES_DIR/scripts/sway-run.sh" ]; then
    doas cp "$DOTFILES_DIR/scripts/sway-run.sh" /usr/local/bin/sway-run
    doas chmod +x /usr/local/bin/sway-run
    ok "sway-run wrapper installed."
else
    fail "scripts/sway-run.sh not found in repo!"
    exit 1
fi

doas mkdir -p /etc/greetd

doas tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 7

[default_session]
command = "tuigreet --cmd sway-run"
user = "greetd"
EOF

doas tee /etc/conf.d/greetd > /dev/null << 'EOF'
rc_need=seatd
EOF

doas rc-update add greetd default
ok "greetd display manager configured. Reboot to start."

info "Cleaning up old .profile autostart entries..."
PROFILE_FILE="$HOME/.profile"
if [ -f "$PROFILE_FILE" ]; then
    doas sed -i '/exec \/usr\/local\/bin\/sway-run/d' "$PROFILE_FILE"
    doas sed -i '/exec dbus-run-session sway/d' "$PROFILE_FILE"
    doas sed -i '/exec sway/d' "$PROFILE_FILE"
    ok "Old autostart entries removed from .profile."
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


finish_install