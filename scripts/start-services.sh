#!/usr/bin/env bash

if ! pgrep -x "pipewire" >/dev/null 2>&1; then
    pipewire &
    sleep 1
fi

if ! pgrep -f "pipewire-pulse" >/dev/null 2>&1; then
    pipewire-pulse &
    sleep 0.5
fi

if ! pgrep -x "wireplumber" >/dev/null 2>&1; then
    wireplumber &
fi
