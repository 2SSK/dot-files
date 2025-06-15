#!/usr/bin/env bash

# Directory containing wallpapers
wallpaper_dir="$HOME/Wallpaper-Bank/"

# Get a random wallpaper from the directory
wallpaper=$(find "$wallpaper_dir" -type f | shuf -n 1)

# Kill any previous swaybg instances to avoid stacking
killall swaybg 2>/dev/null

# Set the new wallpaper using swaybg
swaybg -m fill -i "$wallpaper" &
