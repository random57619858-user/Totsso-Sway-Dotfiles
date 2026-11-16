info "Configuring greetd display manager..."
doas adduser greetd seat 2>/dev/null || true
doas rc-update add seatd default 2>/dev/null || true
doas rc-service seatd start 2>/dev/null || true

if [ -f "$DOTFILES_DIR/scripts/sway-run.sh" ]; then
    doas cp "$DOTFILES_DIR/scripts/sway-run.sh" /usr/local/bin/sway-run
    doas chmod +x /usr/local/bin/sway-run
else
    fail "sway-run.sh not found!"
    exit 1
fi

doas mkdir -p /etc/greetd

doas tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 7

[default_session]
command = "sway-run"
user = "greetd"
EOF

doas tee /etc/conf.d/greetd > /dev/null << 'EOF'
rc_need=seatd
EOF

doas rc-update add greetd default
ok "greetd configured. Reboot to start."
