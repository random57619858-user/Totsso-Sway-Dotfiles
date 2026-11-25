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

info "Checking/Installing trizen (AUR helper)..."
if ! command -v trizen >/dev/null 2>&1; then
    info "Installing trizen..."
    sudo pacman -S --needed --noconfirm git base-devel
    TMP_TRIZEN="$(mktemp_tracked)"
    git clone https://aur.archlinux.org/trizen.git "$TMP_TRIZEN/trizen"
    ( cd "$TMP_TRIZEN/trizen" && makepkg -si --noconfirm )
    ok "trizen installed."
else
    ok "trizen is already installed."
fi

trizen_enable_sudoloop

info "Installing base packages from official repositories..."
sudo pacman -S --needed --noconfirm \
    sway swaybg waybar kitty fish rofi xorg-xwayland \
    playerctl brightnessctl mako wl-clipboard grim slurp ffmpeg \
    xdg-desktop-portal-wlr cava nautilus nwg-look xdg-desktop-portal-gtk \
    polkit-kde-agent cliphist fastfetch \
    xdg-user-dirs git unzip base-devel wget curl \
    wayland wayland-protocols libxkbcommon \
    cairo meson elogind ninja \
    imagemagick python \
     wlogout hyprlock
ok "Base packages installed."

install_matugen

info "Checking init system..."
INIT_COMM="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
if [ "$INIT_COMM" != "openrc-init" ] && [ ! -d /run/openrc ]; then
    fail "OpenRC not detected (init: ${INIT_COMM:-unknown})."
    fail "This installer supports Artix Linux with OpenRC only."
    exit 1
fi
ok "OpenRC detected."

info "Installing PipeWire packages..."
sudo pacman -S --needed --noconfirm pipewire wireplumber \
    pipewire-openrc wireplumber-openrc pipewire-pulse-openrc

info "Configuring Fish shell..."
if command -v fish >/dev/null 2>&1; then
    fish -c "set -U fish_greeting"
    ok "Fish greeting disabled."
else
    warn "Fish not found; skipping configuration."
fi

if ! install_nerd_font; then
    warn "JetBrainsMono Nerd Font is missing; install it manually to see the icons."
fi

if ! install_icons; then
    warn "Fluent icons are missing; install them manually to see app icons."
fi

info "Applying GTK settings..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
for d in gtk-3.0 gtk-4.0; do
    if [ -L "$HOME/.config/$d/gtk.css" ]; then rm -f "$HOME/.config/$d/gtk.css"; fi
done
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

if grep -q "dbus-run-session sway" "$PROFILE_FILE"; then
    ok "Sway autostart already configured."
elif confirm "Start Sway automatically on tty1 when you log in?"; then
    cat >> "$PROFILE_FILE" << 'EOF'

if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
    exec dbus-run-session sway
fi
EOF
    ok "Sway autostart with D-Bus configured in $PROFILE_FILE"
else
    warn "Autostart skipped; start Sway manually with: dbus-run-session sway"
fi

info "Setting up printer support (optional)..."
INSTALL_CUPS=false
if confirm "Install printer support (CUPS + network discovery)?"; then
    INSTALL_CUPS=true
    sudo pacman -S --needed --noconfirm cups cups-pdf avahi nss-mdns \
        gutenprint foomatic-db foomatic-db-ppds system-config-printer
    sudo pacman -S --needed --noconfirm cups-openrc avahi-openrc
fi

info "Configuring OpenRC services..."
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

step "Optional Apps"

choose_one() {
    local prompt="$1"; shift
    local total="$#"
    local i=1
    local opt

    if [ "$AUTO_INSTALL" = true ]; then
        printf "1\n"
        return 0
    fi

    if ! { exec 3<>/dev/tty; } 2>/dev/null; then
        printf "0\n"
        return 0
    fi

    printf "\n %b%s%b\n" "${WHITE:-}" "$prompt" "${RESET:-}" >&3
    printf " %b  0) Skip%b\n" "${GRAY:-}" "${RESET:-}" >&3
    for opt in "$@"; do
        printf " %b  %d) %b%s%b\n" "${GRAY:-}" "$i" "${WHITE:-}" "$opt" "${RESET:-}" >&3
        i=$((i+1))
    done

    local reply=""
    printf " %b%b%bChoose [0-%d]%b:%b " "${YELLOW:-}" "${BOLD:-}" "${WHITE:-}" "$total" "${GRAY:-}" "${RESET:-}" >&3
    read -r reply <&3 || reply=""
    reply="${reply//[[:space:]]/}"
    printf "\n" >&3
    exec 3>&-

    if ! [[ "$reply" =~ ^[0-9]+$ ]] || [ "$reply" -lt 0 ] || [ "$reply" -gt "$total" ]; then
        printf "0\n"
        return 0
    fi

    printf "%s\n" "$reply"
    return 0
}

PKG=""
sel="$(choose_one "Which browser do you want?" "brave-bin (Recommended)" "ungoogled-chromium" "zen-browser-bin")"
case "$sel" in
    1) PKG="brave-bin" ;;
    2) PKG="ungoogled-chromium" ;;
    3) PKG="zen-browser-bin" ;;
    *) PKG="" ;;
esac
if [ -n "$PKG" ]; then
    info "Installing $PKG via trizen..."
    aur_install "$PKG" && ok "$PKG installed." || warn "Failed to install $PKG."
else
    ok "Skipping browser."
fi

PKG=""
sel="$(choose_one "Which Discord client do you want?" "serein-bin (Recommended)" "legcord-bin" "dissent-bin")"
case "$sel" in
    1) PKG="serein-bin" ;;
    2) PKG="legcord-bin" ;;
    3) PKG="dissent-bin" ;;
    *) PKG="" ;;
esac
if [ -n "$PKG" ]; then
    info "Installing $PKG via trizen..."
    aur_install "$PKG" && ok "$PKG installed." || warn "Failed to install $PKG."
else
    ok "Skipping Discord client."
fi

PKG=""
sel="$(choose_one "Which music streaming app do you want?" "simpmusic-bin (Recommended)" "limusic-bin")"
case "$sel" in
    1) PKG="simpmusic-bin" ;;
    2) PKG="limusic-bin" ;;
    *) PKG="" ;;
esac
if [ -n "$PKG" ]; then
    info "Installing $PKG via trizen..."
    aur_install "$PKG" && ok "$PKG installed." || warn "Failed to install $PKG."
else
    ok "Skipping music app."
fi

PKG=""
sel="$(choose_one "Which office suite do you want?" "onlyoffice-bin (Recommended)" "openoffice-bin")"
case "$sel" in
    1) PKG="onlyoffice-bin" ;;
    2) PKG="openoffice-bin" ;;
    *) PKG="" ;;
esac
if [ -n "$PKG" ]; then
    info "Installing $PKG via trizen..."
    aur_install "$PKG" && ok "$PKG installed." || warn "Failed to install $PKG."
else
    ok "Skipping office suite."
fi

PKG=""
sel="$(choose_one "Which code editor do you want?" "vscodium-bin (Recommended)" "lapce-git (No -bin)")"
case "$sel" in
    1) PKG="vscodium-bin" ;;
    2) PKG="lapce-git" ;;
    *) PKG="" ;;
esac
if [ -n "$PKG" ]; then
    info "Installing $PKG via trizen..."
    aur_install "$PKG" && ok "$PKG installed." || warn "Failed to install $PKG."
else
    ok "Skipping code editor."
fi

info "Installing Flatpak + Flathub (optional)..."
if confirm "Install Flatpak + Flathub?"; then
    sudo pacman -S --needed --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    ok "Flatpak and Flathub configured."
fi

setup_all_dotfiles
finish_install
