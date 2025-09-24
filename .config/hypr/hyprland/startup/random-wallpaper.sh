#!/bin/bash
WALLPAPER=$(find ~/Wallpaper-Bank -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | shuf -n 1)
waypaper --wallpaper "$WALLPAPER"
