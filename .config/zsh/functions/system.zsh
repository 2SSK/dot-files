#!/usr/bin/env zsh
# System-related functions

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# System information
sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
}

# Colored man pages function
man() {
    LESS_TERMCAP_mb=$'\e[1;32m' \
    LESS_TERMCAP_md=$'\e[1;32m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[1;4;31m' \
    command man "$@"
}

# Install useful tools (fzf and ripgrep)
install_tools() {
    echo "Installing fzf and ripgrep..."

    # Install fzf
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Installing fzf..."
        sudo apt update && sudo apt install -y fzf
    else
        echo "fzf already installed"
    fi

    # Install ripgrep
    if ! command -v rg >/dev/null 2>&1; then
        echo "Installing ripgrep..."
        sudo apt update && sudo apt install -y ripgrep
    else
        echo "ripgrep already installed"
    fi

    echo "Tools installation complete!"
    echo "Reload your shell with: source ~/.zshrc"
}
