#!/usr/bin/env bash
set -uo pipefail

WATCHER="org.kde.StatusNotifierWatcher"
WPATH="/StatusNotifierWatcher"
WPROP="org.kde.StatusNotifierWatcher"

watcher_items() {
    busctl --user get-property "$WATCHER" "$WPATH" "$WPROP" \
        RegisteredStatusNotifierItems 2>/dev/null |
        sed 's/^as [0-9]*[[:space:]]*//' | tr -d '"' | tr ' ' '\n' | grep -v '^$'
}

rescan() {
    local current name
    current=$(watcher_items)
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        case " $current " in
            *"$name"*) continue ;;
        esac
        busctl --user call "$WATCHER" "$WPATH" "$WPROP" \
            RegisterStatusNotifierItem s "$name" >/dev/null 2>&1
    done < <(busctl --user list --no-legend 2>/dev/null |
        awk '$1 ~ /^org\.kde\.StatusNotifierItem-/ {print $1}')
}

sleep "${2:-0}"
rescan
