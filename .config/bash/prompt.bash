#!/usr/bin/env bash

# Color definitions
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
YELLOW="\[\e[1;33m\]"
BLUE="\[\e[1;34m\]"
MAGENTA="\[\e[1;35m\]"
CYAN="\[\e[1;36m\]"
WHITE="\[\e[1;37m\]"
ENDC="\[\e[0m\]"

# Git prompt function
parse_git_branch(){
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    return
  fi
  
  local branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  local status=$(git status --porcelain 2> /dev/null)
  
  if [ -z "$status" ]; then
    echo " (${branch} ✓)"  # Clean
  else
    echo " (${branch} ✗)"  # Dirty
  fi
}

# Set prompt with git branch
if [[ -n "$SSH_CLIENT" ]]; then
  ssh_message="${RED}-ssh${ENDC}"
else
  ssh_message=""
fi

# Battery status function
battery_status() {
    local bat_path="/sys/class/power_supply/BAT1"
    if [ ! -d "$bat_path" ]; then
        bat_path="/sys/class/power_supply/BAT0"
    fi
    
    if [ -d "$bat_path" ]; then
        local cap=$(cat "$bat_path/capacity")
        echo "⚡${cap}%"
    fi
}

# Enhanced prompt with git branch and battery
PS1="${GREEN}\u${ssh_message} ${WHITE}at ${YELLOW}\h ${WHITE}in ${BLUE}\w${CYAN}\$(parse_git_branch)\n${MAGENTA}\$(battery_status) ${CYAN}\$${ENDC} "
