# if type "xrandr"; then
#   for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
#     MONITOR=$m polybar --reload top &
#     MONITOR=$m polybar --reload bottom &
#   done
# else
#   polybar --reload top &
#   polybar --reload bottom &
# fi

#!/bin/bash

# Kill existing polybar instances
killall -q polybar

# Wait until the processes are fully gone
while pgrep -x polybar >/dev/null; do sleep 0.5; done

# Only launch on eDP-1-1
MONITOR="eDP-1-1"
polybar --reload top &
polybar --reload bottom &
