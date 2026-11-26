#!/usr/bin/env bash
set -uo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
CACHE="$RUNTIME/waybar-background.cache"
SLOTS="$RUNTIME/waybar-background.slots"
TTL=1

mkdir -p "$SLOTS"

read -r -d '' PY_SRC <<'PY'
import json
import re
import subprocess
import sys


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=4).stdout
    except Exception:
        return ""


tray = []
raw = run(["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher",
           "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher",
           "RegisteredStatusNotifierItems"])
for entry in re.findall(r'"([^"]+)"', raw):
    service, _, path = entry.partition("/")
    title = run(["busctl", "--user", "get-property", service, "/" + path,
                 "org.kde.StatusNotifierItem", "Title"]).strip()
    title = re.sub(r'^s\s*', "", title).strip('"')
    tray.append(title or path.split("/")[-1])

def ancestors(pid, depth=6):
    seen = set()
    while pid and depth > 0:
        seen.add(pid)
        try:
            with open("/proc/%s/status" % pid) as fh:
                for line in fh:
                    if line.startswith("PPid:"):
                        pid = line.split()[1]
                        break
                else:
                    break
        except Exception:
            break
        depth -= 1
    return seen


visible = set()
window_ids = set()
tree = run(["swaymsg", "-t", "get_tree", "-r"])
if tree:
    try:
        root = json.loads(tree)
    except Exception:
        root = None

    def walk(node):
        for key in ("nodes", "floating_nodes"):
            for child in node.get(key) or []:
                walk(child)
        if node.get("type") == "con" and node.get("pid"):
            visible.add(str(node["pid"]))
            if node.get("app_id"):
                window_ids.add(node["app_id"].lower())

    if root:
        walk(root)

ignore = {"waybar", "cava", "pipewire", "wireplumber", "pulseaudio", "pw-cat"}
audio = {}
for block in run(["pactl", "list", "sink-inputs"]).split("Sink Input #")[1:]:
    name = re.search(r'application\.name = "([^"]*)"', block)
    pid = re.search(r'application\.process\.id = "([^"]*)"', block)
    binary = re.search(r'application\.process\.binary = "([^"]*)"', block)
    if not name:
        continue
    name = name.group(1)
    pid = pid.group(1) if pid else ""
    binary = (binary.group(1) if binary else name).lower()
    if pid and (ancestors(pid) & visible):
        continue
    if any(name.lower() in app or app in name.lower() for app in window_ids):
        continue
    if binary in ignore or name.lower() in ignore:
        continue
    if any(name.lower() == item.lower() for item in tray):
        continue
    audio.setdefault(name, pid)

for item in tray:
    print("tray\t%s" % item)

for name, pid in audio.items():
    print("audio\t%s\t%s" % (name, pid))
PY

gather() {
    local now mtime
    now=$(date +%s)
    if [ -f "$CACHE" ]; then
        mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
        if (( now - mtime < TTL )); then
            cat "$CACHE"
            return 0
        fi
    fi
    python3 -c "$PY_SRC" > "$CACHE.new" 2>/dev/null
    mv -f "$CACHE.new" "$CACHE" 2>/dev/null
    cat "$CACHE" 2>/dev/null
}

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

app_icon() {
    local key="${1,,}"
    case "$key" in
        *simp*|*music*|*spotify*|*ncspot*|*tidal*|*rhythmbox*|*amberol*|*cider*)
            printf '󰝚' ;;
        *discord*|*vesktop*|*webcord*|*equibop*)
            printf '󰙯' ;;
        *telegram*|*signal*|*whatsapp*|*element*|*slack*|*matrix*)
            printf '󰍡' ;;
        *mpv*|*vlc*|*celluloid*|*haruna*|*youtube*)
            printf '󰖜' ;;
        *firefox*|*brave*|*chrom*|*zen*|*qutebrowser*)
            printf '󰖟' ;;
        *steam*|*lutris*|*heroic*|*prism*)
            printf '󰊗' ;;
        *keepass*|*bitwarden*|*1password*)
            printf '󰌾' ;;
        *)
            printf '󰖲' ;;
    esac
}

mode_count() {
    local data trays audios total tooltip
    data=$(gather)
    trays=$(printf '%s' "$data" | grep -c '^tray' || true)
    audios=$(printf '%s' "$data" | grep -c '^audio' || true)
    total=$(( trays + audios ))

    if (( total == 0 )); then
        printf '{"text": "󰅁", "class": "none", "tooltip": "Sin apps en segundo plano"}\n'
        return 0
    fi

    tooltip=$(printf '%s' "$data" | awk -F'\t' '/^(tray|audio)\t/ { printf "%s· %s", (n++ ? "\n" : ""), $2 }')
    printf '{"text": "󰅁 %d", "class": "has-items", "tooltip": "%s"}\n' \
        "$total" "$(jesc "$tooltip")"
}

mode_slot() {
    local idx="$1" data line name pid icon
    data=$(gather)
    line=$(printf '%s\n' "$data" | grep '^audio' | sed -n "${idx}p")
    if [ -z "$line" ]; then
        rm -f "$SLOTS/$idx"
        printf '{"text": "", "class": "empty"}\n'
        return 0
    fi
    IFS=$'\t' read -r _ name pid <<< "$line"
    printf '%s\t%s' "$name" "$pid" > "$SLOTS/$idx"
    icon=$(app_icon "$name")
    printf '{"text": "%s", "class": "bgapp", "tooltip": "%s"}\n' "$icon" "$(jesc "$name")"
}

mode_focus() {
    local idx="$1" name pid
    [ -r "$SLOTS/$idx" ] || return 0
    IFS=$'\t' read -r name pid < "$SLOTS/$idx"
    [ -n "${pid:-}" ] || return 0
    swaymsg "[pid=$pid] focus" >/dev/null 2>&1
    rm -f "$CACHE"
}

case "${1:-count}" in
    count) mode_count ;;
    slot)  mode_slot "${2:-1}" ;;
    focus) mode_focus "${2:-1}" ;;
    *)     mode_count ;;
esac
