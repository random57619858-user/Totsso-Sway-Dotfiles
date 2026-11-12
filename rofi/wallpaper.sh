#!/bin/bash

CACHE_FILE="$HOME/.cache/current_wallpaper"
MATUGEN_BIN="$HOME/.cargo/bin/matugen"

detect_image_dir() {
    for dir in "$HOME/Pictures" "$HOME/Images" "$HOME/Imágenes"; do
        if [ -d "$dir" ]; then
            if [ -n "$(find "$dir" -maxdepth 1 -type f 2>/dev/null)" ]; then
                echo "$dir"
                return 0
            fi
        fi
    done
    echo "$HOME"
    return 0
}

cleanup_wallpaper() {
    pkill -x swaybg 2>/dev/null || true
    pkill -x mpvpaper 2>/dev/null || true
}

apply_wallpaper() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"

    cleanup_wallpaper

    case "$ext" in
        png|jpg|jpeg|webp)
            if command -v swaybg &>/dev/null; then
                setsid swaybg -i "$file" -m fill >/dev/null 2>&1 < /dev/null &
            fi
            ;;
    esac
}

apply_matugen() {
    local file="$1"
    
    if [ ! -x "$MATUGEN_BIN" ]; then
        notify-send "Wallpaper" "Matugen not found at $MATUGEN_BIN"
        return 1
    fi

    local cache_img="$HOME/.cache/current_wallpaper.jpg"
    cp "$file" "$cache_img" 2>/dev/null
    
    "$MATUGEN_BIN" image "$file" --source-color-index 0 >/dev/null 2>&1

    pkill -x waybar 2>/dev/null || true
    sleep 0.5
    setsid waybar >/dev/null 2>&1 < /dev/null &
    
    pkill -SIGUSR1 -x kitty 2>/dev/null || true

    swaymsg reload >/dev/null 2>&1 || true
}

if [ "${1:-}" = "restore" ]; then
    sleep 0.5
    [ -f "$CACHE_FILE" ] || exit 0
    saved=$(cat "$CACHE_FILE")
    [ -f "$saved" ] || exit 0
    apply_wallpaper "$saved"
    apply_matugen "$saved"
    exit 0
fi

if ! command -v rofi &>/dev/null; then
    notify-send "Wallpaper" "Rofi is not installed"
    exit 1
fi

IMAGE_DIR=$(detect_image_dir)

TEMP_LIST=$(mktemp)
trap 'rm -f "$TEMP_LIST"' EXIT

find "$IMAGE_DIR" -maxdepth 3 -type f \( \
    -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \
\) -printf "%P|%p\n" 2>/dev/null | sort > "$TEMP_LIST"

if [ ! -s "$TEMP_LIST" ]; then
    notify-send "Wallpaper" "No images found in $IMAGE_DIR"
    exit 1
fi

chosen=$(awk -F'|' '{print $1}' "$TEMP_LIST" | rofi -dmenu -p "󰸉 Wallpaper" -i -matching fuzzy)

if [ -n "${chosen:-}" ]; then
    full_path=$(grep -F "$chosen|" "$TEMP_LIST" | head -n 1 | cut -d'|' -f2-)
    if [ -f "$full_path" ]; then
        mkdir -p "$(dirname "$CACHE_FILE")"
        echo "$full_path" > "$CACHE_FILE"
        apply_wallpaper "$full_path"
        apply_matugen "$full_path"
    fi
fi
