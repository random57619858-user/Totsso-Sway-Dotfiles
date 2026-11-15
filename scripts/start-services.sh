#!/usr/bin/env bash

# Lanzar PipeWire si no está corriendo
if ! pgrep -x "pipewire" > /dev/null; then
    pipewire &
fi
if ! pgrep -x "pipewire-pulse" > /dev/null; then
    pipewire-pulse &
fi
if ! pgrep -x "wireplumber" > /dev/null; then
    wireplumber &
fi

if command -v cupsd >/dev/null 2>&1; then
    if ! pgrep -x "cupsd" > /dev/null; then
        /usr/bin/cupsd &
    fi
fi

if command -v avahi-daemon >/dev/null 2>&1; then
    if ! pgrep -x "avahi-daemon" > /dev/null; then
        /usr/bin/avahi-daemon --daemonize --no-chroot &
    fi
fi

if [ -f /usr/lib/elogind/elogind ]; then
    if ! pgrep -x "elogind" > /dev/null; then
        /usr/lib/elogind/elogind &
    fi
fi
