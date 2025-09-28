#!/bin/sh

# Source .profile for common environment vars
. ~/.profile

# Disable access control for the current user
xhost +SI:localuser:$USER

# Make Java applications aware this is a non-reparenting window manager
export _JAVA_AWT_WM_NONREPARENTING=1

# Start Shepherd to manage user daemons
if [ -z "$(pgrep -u elliott shepherd)" ]; then
  shepherd
fi

# Run xsettingsd to progagate font and theme settings
xsettingsd &

# Enable screen compositing
compton &

# Turn off the system bell
xset -b

# Enable screen locking on suspend
xss-lock -- slock &

# Fire it up
exec dbus-launch --exit-with-session emacs -mm --debug-init -l ~/.dotfiles/.emacs.d/desktop.el
