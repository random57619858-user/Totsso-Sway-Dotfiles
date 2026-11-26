#!/usr/bin/env bash
set -uo pipefail

WATCHER="org.kde.StatusNotifierWatcher"
WPATH="/StatusNotifierWatcher"
WPROP="org.kde.StatusNotifierWatcher"

jesc() {
    local s="${1-}"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

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

item_label() {
    local entry="$1" svc obj pid name title
    svc="${entry%%/*}"
    obj="/${entry#*/}"
    pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetConnectionUnixProcessID s "$svc" 2>/dev/null | sed 's/^u //')
    if [ -n "$pid" ] && [ -r "/proc/$pid/comm" ]; then
        name=$(cat "/proc/$pid/comm")
    fi
    if [ -z "${name:-}" ]; then
        title=$(busctl --user get-property "$svc" "$obj" \
            org.kde.StatusNotifierItem Title 2>/dev/null | sed -e 's/^s //' -e 's/^"//' -e 's/"$//')
        name=$(printf '%b' "${title:-${obj##*/}}")
    fi
    printf '%s' "${name^}"
}

if [ "${1:-count}" = "rescan" ]; then
    rescan
    exit 0
fi

rescan

count=0
tooltip=""
while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    count=$((count + 1))
    tooltip+="· $(item_label "$entry")"$'\n'
done < <(watcher_items)

if (( count == 0 )); then
    printf '{"text": "󰅁", "class": "none", "tooltip": "Bandeja vacía"}\n'
    exit 0
fi

plural="s"
(( count == 1 )) && plural=""
printf '{"text": "󰅁 %d", "class": "has-items", "tooltip": "%d app%s en la bandeja\\n%s"}\n' \
    "$count" "$count" "$plural" "$(jesc "${tooltip%$'\n'}")"
