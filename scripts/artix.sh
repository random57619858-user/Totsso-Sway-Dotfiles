#!/usr/bin/env bash

if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required but not installed. Aborting."
    exit 1
fi

if ! sudo -v; then
    fail "sudo is required. Aborting."
    exit 1
fi

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
    sway swaybg waybar kitty fish rofi \
    playerctl brightnessctl mako wl-clipboard grim slurp ffmpeg \
    xdg-desktop-portal-wlr cava nautilus nwg-look xdg-desktop-portal-gtk \
    polkit-kde-agent cliphist \
    xdg-user-dirs git unzip base-devel wget curl \
    wayland wayland-protocols libxkbcommon \
    cairo meson elogind ninja \
    hyprlock
ok "Base packages installed."

info "Detecting init system..."
INIT_SYSTEM="unknown"
if [ -d /run/openrc ]; then INIT_SYSTEM="openrc"
elif [ -d /run/runit ]; then INIT_SYSTEM="runit"
elif [ -d /run/s6-rc ]; then INIT_SYSTEM="s6"
elif command -v dinitctl >/dev/null 2>&1; then INIT_SYSTEM="dinit"
fi
ok "Detected init system: $INIT_SYSTEM"

info "Installing PipeWire packages for $INIT_SYSTEM..."
sudo pacman -S --needed --noconfirm pipewire wireplumber

if [ "$INIT_SYSTEM" == "openrc" ]; then
    sudo pacman -S --needed --noconfirm pipewire-openrc wireplumber-openrc pipewire-pulse-openrc
elif [ "$INIT_SYSTEM" == "runit" ]; then
    sudo pacman -S --needed --noconfirm pipewire-runit wireplumber-runit pipewire-pulse-runit
elif [ "$INIT_SYSTEM" == "s6" ]; then
    sudo pacman -S --needed --noconfirm pipewire-s6 wireplumber-s6 pipewire-pulse-s6
elif [ "$INIT_SYSTEM" == "dinit" ]; then
    sudo pacman -S --needed --noconfirm pipewire-dinit wireplumber-dinit pipewire-pulse-dinit
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

info "Setting up printer support (optional)..."
INSTALL_CUPS=false
if confirm "Install printer support (CUPS + network discovery)?"; then
    INSTALL_CUPS=true
    sudo pacman -S --needed --noconfirm cups cups-pdf avahi nss-mdns \
        gutenprint foomatic-db foomatic-db-ppds system-config-printer
    if [ "$INIT_SYSTEM" == "openrc" ]; then
        sudo pacman -S --needed --noconfirm cups-openrc avahi-openrc 2>/dev/null || true
    fi
fi

info "Configuring services..."
if [ "$INIT_SYSTEM" == "openrc" ]; then
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
    
    sudo rc-update add elogind boot 2>/dev/null || true
    sudo rc-service elogind start 2>/dev/null || true

    if [ "$INSTALL_CUPS" = true ]; then
        sudo rc-update add cupsd default
        sudo rc-update add avahi-daemon default
        sudo rc-service cupsd start
        sudo rc-service avahi-daemon start
    fi
    ok "OpenRC services configured."
else
    warn "Non-OpenRC init detected ($INIT_SYSTEM). Using universal autostart script."
    
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

setup_all_dotfiles
finish_install
