#!/bin/sh
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export LIBSEAT_BACKEND=seatd

export WLR_RENDERER_ALLOW_SOFTWARE=1
export WLR_LIBINPUT_NO_DEVICES=1

if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/tmp/xdg/$(id -u)-runtime-dir"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 0700 "$XDG_RUNTIME_DIR"
fi

exec dbus-run-session sway "$@"
