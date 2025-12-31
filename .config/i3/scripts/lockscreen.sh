#!/bin/sh

# Colors (Tokyonight)
BLANK='#00000000'
BG='#1a1b26'
CLEAR='#ffffff22'
DEFAULT='#7aa2f7'
TEXT='#c0caf5'
WRONG='#f7768e'
VERIFYING='#9ece6a'

i3lock \
  --image=/home/ssk/Wallpaper-Bank/heart_original.png \
  --fill \
  --color=$BG \
  --insidever-color=$CLEAR \
  --ringver-color=$VERIFYING \
  \
  --insidewrong-color=$CLEAR \
  --ringwrong-color=$WRONG \
  \
  --inside-color=$BLANK \
  --ring-color=$DEFAULT \
  --line-color=$BLANK \
  --separator-color=$DEFAULT \
  \
  --verif-color=$TEXT \
  --wrong-color=$TEXT \
  --time-color=$TEXT \
  --date-color=$TEXT \
  --layout-color=$TEXT \
  --keyhl-color=$WRONG \
  --bshl-color=$WRONG \
  \
  --time-size=24 \
  --date-size=16 \
  --layout-size=22 \
  \
  --clock \
  --indicator \
  --time-str="%I:%M:%S %p" \
  --date-str="%a, %b %d" 
