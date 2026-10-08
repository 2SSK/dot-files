#!/bin/bash

WALLPAPER_DIR=~/Wallpaper-Bank
STATE_FILE=~/.cache/wallpaper_list.txt

# Ensure cache dir exists
mkdir -p "$(dirname "$STATE_FILE")"

# If state file doesn't exist or is empty, (re)populate it
if [[ ! -s "$STATE_FILE" ]]; then
  find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) |
    shuf >"$STATE_FILE"
fi

# Take the first wallpaper from the list
WALLPAPER=$(head -n 1 "$STATE_FILE")

# Remove it from the list (so it won't be reused until rotation is complete)
sed -i '1d' "$STATE_FILE"

# Set wallpaper
waypaper --wallpaper "$WALLPAPER"
