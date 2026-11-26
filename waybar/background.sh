#!/usr/bin/env bash
set -uo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
CACHE="$RUNTIME/waybar-background.cache"
SLOTS="$RUNTIME/waybar-background.slots"
TTL=1

mkdir -p "$SLOTS"

read -r -d '' PY_SRC <<'PY'
import json
import os
import re
import subprocess


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=4).stdout
    except Exception:
        return ""


def norm(text):
    return re.sub(r"[^a-z0-9]", "", (text or "").lower())


def display_name(raw):
    name = (raw or "?").split(".")[-1]
    name = name.replace("_", " ").replace("-", " ").strip()
    return name[:1].upper() + name[1:] if name else "?"


def comm(pid):
    try:
        with open("/proc/%s/comm" % pid) as fh:
            return fh.read().strip()
    except Exception:
        return ""


windows = []
tree = run(["swaymsg", "-t", "get_tree", "-r"])
if tree:
    try:
        root = json.loads(tree)
    except Exception:
        root = None

    def walk(node, ws=None):
        if node.get("type") == "workspace":
            ws = node.get("name")
        for key in ("nodes", "floating_nodes"):
            for child in node.get(key) or []:
                walk(child, ws)
        if node.get("type") == "con" and node.get("pid"):
            props = node.get("window_properties") or {}
            pid = str(node["pid"])
            windows.append({
                "pid": pid,
                "comm": norm(comm(pid)),
                "name": node.get("app_id") or props.get("class") or "?",
                "ws": ws or "?",
                "visible": bool(node.get("visible")),
                "con": str(node.get("id")),
            })

    if root:
        walk(root)

window_pids = {win["pid"] for win in windows}
window_comms = {win["comm"] for win in windows if win["comm"]}


def has_window(pid, binary=""):
    if pid and pid in window_pids:
        return True
    key = norm(binary)
    if key and key in window_comms:
        return True
    if key and len(key) >= 4:
        for other in window_comms:
            if key in other or other in key:
                return True
    return False


rows = []

for win in windows:
    if win["visible"]:
        continue
    rows.append((win["name"], win["pid"], win["ws"], win["con"]))

raw = run(["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher",
           "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher",
           "RegisteredStatusNotifierItems"])
for entry in re.findall(r'"([^"]+)"', raw):
    service, _, path = entry.partition("/")
    pid = run(["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
               "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", service]).strip()
    pid = re.sub(r"^u\s*", "", pid)
    title = run(["busctl", "--user", "get-property", service, "/" + path,
                 "org.kde.StatusNotifierItem", "Title"]).strip()
    title = re.sub(r"^s\s*", "", title).strip('"')
    name = title or path.split("/")[-1]
    if has_window(pid, comm(pid) if pid else name):
        continue
    rows.append((name, pid, "-", ""))

ignore = {"waybar", "cava", "pipewire", "wireplumber", "pulseaudio", "pwcat"}
for block in run(["pactl", "list", "sink-inputs"]).split("Sink Input #")[1:]:
    name = re.search(r'application\.name = "([^"]*)"', block)
    pid = re.search(r'application\.process\.id = "([^"]*)"', block)
    binary = re.search(r'application\.process\.binary = "([^"]*)"', block)
    if not name:
        continue
    name = name.group(1)
    pid = pid.group(1) if pid else ""
    binary = binary.group(1) if binary else name
    if norm(binary) in ignore or norm(name) in ignore:
        continue
    if has_window(pid, binary):
        continue
    rows.append((name, pid, "-", ""))

seen = set()
for name, pid, ws, con in rows:
    key = pid or name.lower()
    if key in seen:
        continue
    seen.add(key)
    print("\t".join([name, display_name(name), ws, con, pid]))
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
    local key="${1,,}" letter
    case "$key" in
        *serein*|*discord*|*vesktop*|*webcord*|*equibop*|*armcord*)
            printf '󰙯' ;;
        *simp*|*music*|*spotify*|*ncspot*|*tidal*|*rhythmbox*|*amberol*|*cider*|*mpd*|*feishin*)
            printf '󰝚' ;;
        *telegram*|*signal*|*whatsapp*|*element*|*slack*|*matrix*|*zulip*|*mattermost*)
            printf '󰍡' ;;
        *mpv*|*vlc*|*celluloid*|*haruna*|*youtube*)
            printf '󰖜' ;;
        *firefox*|*brave*|*chrom*|*zen*|*qutebrowser*|*vivaldi*|*epiphany*|*falkon*|*tor-browser*)
            printf '󰖟' ;;
        *kitty*|*alacritty*|*foot*|*wezterm*|*konsole*|*terminal*|*xterm*|*ghostty*|*nvim*|*neovide*|*vim*|*emacs*)
            printf '󰆍' ;;
        *code*|*vscodium*|*cursor*|*zed*|*sublime*|*idea*|*studio*)
            printf '󰨞' ;;
        *thunar*|*nautilus*|*dolphin*|*pcmanfm*|*nemo*|*caja*|*files*)
            printf '󰉋' ;;
        *gimp*|*inkscape*|*krita*|*imv*|*loupe*|*eog*|*gwenview*)
            printf '󰈟' ;;
        *libreoffice*|*writer*|*calc*|*impress*|*zathura*|*evince*|*okular*|*pdf*|*onlyoffice*)
            printf '󰈙' ;;
        *steam*|*lutris*|*heroic*|*prism*|*gamescope*|*retroarch*)
            printf '󰊗' ;;
        *keepass*|*bitwarden*|*1password*)
            printf '󰌾' ;;
        *pavucontrol*|*pulse*|*easyeffects*|*wireplumber*)
            printf '󰕾' ;;
        *mail*|*thunderbird*|*evolution*|*geary*)
            printf '󰇮' ;;
        *)
            letter=$(printf '%s' "$key" | tr -cd '[:alnum:]' | cut -c1 | tr '[:lower:]' '[:upper:]')
            if [ -n "$letter" ]; then printf '%s' "$letter"; else printf '󰖲'; fi ;;
    esac
}

mode_count() {
    local data total tooltip
    data=$(gather)
    total=$(printf '%s' "$data" | grep -c . || true)

    if (( total == 0 )); then
        printf '{"text": "󰅁", "class": "none", "tooltip": "Sin apps en segundo plano"}\n'
        return 0
    fi

    tooltip=$(printf '%s' "$data" | awk -F'\t' '{
        label = $2
        if ($3 != "-") label = label " · ws " $3
        printf "%s· %s", (n++ ? "\n" : ""), label
    }')
    printf '{"text": "󰅁 %d", "class": "has-items", "tooltip": "%s"}\n' \
        "$total" "$(jesc "$tooltip")"
}

mode_slot() {
    local idx="$1" data line name display ws con pid icon tip
    data=$(gather)
    line=$(printf '%s\n' "$data" | sed -n "${idx}p")
    if [ -z "$line" ]; then
        rm -f "$SLOTS/$idx"
        printf '{"text": "", "class": "empty"}\n'
        return 0
    fi
    IFS=$'\t' read -r name display ws con pid <<< "$line"
    printf '%s\t%s\t%s\t%s' "$display" "$ws" "$con" "$pid" > "$SLOTS/$idx"
    icon=$(app_icon "$name $display")
    tip="$display"
    [ "$ws" != "-" ] && tip+=" · ws $ws"
    printf '{"text": "%s", "class": "bgapp", "tooltip": "%s"}\n' "$icon" "$(jesc "$tip")"
}

mode_focus() {
    local idx="$1" display ws con pid
    [ -r "$SLOTS/$idx" ] || return 0
    IFS=$'\t' read -r display ws con pid < "$SLOTS/$idx"
    [ -n "${con:-}" ] || return 0
    swaymsg "[con_id=$con] focus" >/dev/null 2>&1
    rm -f "$CACHE"
}

case "${1:-count}" in
    count) mode_count ;;
    slot)  mode_slot "${2:-1}" ;;
    focus) mode_focus "${2:-1}" ;;
    *)     mode_count ;;
esac
