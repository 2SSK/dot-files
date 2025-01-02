#!/bin/sh

# Define colors
BLANK='#00000000'
CLEAR='#ffffff22'
DEFAULT='#a6e3a1'
TEXT='#cdd6f4'
WRONG='#f38ba8'
VERIFYING='#74c7ec'


i3lock \
  --insidever-color=$CLEAR     \
  --ringver-color=$VERIFYING   \
  \
  --insidewrong-color=$CLEAR   \
  --ringwrong-color=$WRONG     \
  \
  --inside-color=$BLANK        \
  --ring-color=$DEFAULT        \
  --line-color=$BLANK          \
  --separator-color=$DEFAULT   \
  \
  --verif-color=$TEXT          \
  --wrong-color=$TEXT          \
  --time-color=$TEXT           \
  --date-color=$TEXT           \
  --layout-color=$TEXT         \
  --keyhl-color=$WRONG         \
  --bshl-color=$WRONG          \
  \
  --time-size=24               \
  --date-size=16               \
  --layout-size=24             \
  \
  --screen 1                   \
  --blur 9                     \
  --clock                      \
  --indicator                  \
  --time-str="%I:%M:%S %p"     \
  --date-str="%a, %Y-%b-%d"    \
  --keylayout 1
