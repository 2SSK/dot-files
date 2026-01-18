#!/bin/bash

# ============================================================================
# Dotfiles Bootstrap Script
# ============================================================================
# A professional installation script for a complete Arch Linux development
# environment with Hyprland, Noctalia Shell, and Tokyo Night theme.
#
# Author: SSK
# Environment: Arch Linux
# WM: Hyprland + Noctalia Shell
# Theme: Tokyo Night
# Shell: ZSH with Oh My Zsh
# Font: JetBrains Mono Nerd Font
# ============================================================================

set -e

# ============================================================================
# CONSTANTS AND CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="$SCRIPT_DIR/install.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Installation steps flags
INSTALL_PACKAGES=true
INSTALL_AUR_HELPER=true
SETUP_DOTFILES=true
SETUP_SHELL=true
SETUP_NVIM=true
SETUP_HYPRLAND=true
INSTALL_THEMES=true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[✗]${NC} $message"
            ;;
        STEP)
            echo -e "\n${MAGENTA}[→]${NC} ${CYAN}$message${NC}"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

error_exit() {
    log ERROR "$1"
    exit 1
}

command_exists() {
    command -v "$1" &>/dev/null
}

package_installed() {
    pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null 2>&1
}

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -rp "$(echo -e "${CYAN}${prompt}${NC} [y/n]: ")" response
        case $response in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

create_backup() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        log INFO "Backing up $1 to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        cp -r "$1" "$BACKUP_DIR/" 2>/dev/null || true
    fi
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_system() {
    log STEP "Performing system checks..."
    
    # Check if running on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        error_exit "This script is designed for Arch Linux only!"
    fi
    
    # Check for sudo privileges
    if ! sudo -v; then
        error_exit "This script requires sudo privileges!"
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &>/dev/null; then
        error_exit "No internet connection detected!"
    fi
    
    log SUCCESS "System checks passed"
}

# ============================================================================
# PACKAGE INSTALLATION
# ============================================================================

install_yay() {
    log STEP "Setting up AUR helper (yay)..."
    
    if command_exists yay; then
        log SUCCESS "yay is already installed"
        return 0
    fi
    
    log INFO "Installing yay..."
    
    # Install base-devel if not present
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and install yay
    local tmp_dir="/tmp/yay-install"
    rm -rf "$tmp_dir"
    git clone https://aur.archlinux.org/yay.git "$tmp_dir"
    cd "$tmp_dir"
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$tmp_dir"
    
    log SUCCESS "yay installed successfully"
}

install_packages() {
    log STEP "Installing system packages..."
    
    local packages_file="$SCRIPT_DIR/arch/packages.txt"
    
    if [ ! -f "$packages_file" ]; then
        error_exit "Package list not found: $packages_file"
    fi
    
    # Update system first
    log INFO "Updating system..."
    sudo pacman -Syu --noconfirm
    
    # Read and install packages
    local installed_count=0
    local skipped_count=0
    local failed_count=0
    
    while IFS= read -r package || [ -n "$package" ]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        package=$(echo "$package" | xargs)
        
        if package_installed "$package"; then
            log INFO "✓ $package (already installed)"
            ((skipped_count++))
        else
            log INFO "Installing $package..."
            if yay -S --noconfirm --needed "$package" 2>&1 | tee -a "$LOG_FILE"; then
                log SUCCESS "$package installed"
                ((installed_count++))
            else
                log ERROR "Failed to install $package"
                ((failed_count++))
            fi
        fi
    done < "$packages_file"
    
    log SUCCESS "Package installation complete"
    log INFO "Installed: $installed_count | Skipped: $skipped_count | Failed: $failed_count"
}

# ============================================================================
# DOTFILES MANAGEMENT
# ============================================================================

setup_dotfiles() {
    log STEP "Setting up dotfiles with GNU Stow..."
    
    if ! command_exists stow; then
        log INFO "Installing stow..."
        sudo pacman -S --noconfirm stow
    fi
    
    # Backup existing dotfiles
    log INFO "Backing up existing dotfiles..."
    for item in .bashrc .zshrc .tmux.conf .vimrc .config; do
        create_backup "$HOME/$item"
    done
    
    # Stow dotfiles
    log INFO "Stowing dotfiles..."
    cd "$SCRIPT_DIR"
    
    # Remove existing symlinks to avoid conflicts
    find . -maxdepth 1 -name ".*" -type f | while read -r file; do
        filename=$(basename "$file")
        if [ -L "$HOME/$filename" ]; then
            rm "$HOME/$filename"
        fi
    done
    
    # Stow all dotfiles
    if stow --restow --target="$HOME" --verbose=1 . 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "Dotfiles stowed successfully"
    else
        log WARNING "Some conflicts occurred during stowing. Check the log."
    fi
}

# ============================================================================
# SHELL CONFIGURATION
# ============================================================================

setup_zsh() {
    log STEP "Configuring ZSH environment..."
    
    # Install ZSH if not present
    if ! command_exists zsh; then
        log INFO "Installing ZSH..."
        sudo pacman -S --noconfirm zsh
    fi
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log INFO "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log INFO "Oh My Zsh already installed"
    fi
    
    # Install ZSH plugins
    local custom_plugins="$HOME/.oh-my-zsh/custom/plugins"
    
    # zsh-autosuggestions
    if [ ! -d "$custom_plugins/zsh-autosuggestions" ]; then
        log INFO "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "$custom_plugins/zsh-syntax-highlighting" ]; then
        log INFO "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins/zsh-syntax-highlighting"
    fi
    
    # Install Starship prompt
    if ! command_exists starship; then
        log INFO "Installing Starship prompt..."
        yay -S --noconfirm starship
    fi
    
    # Build bat theme cache
    if command_exists bat; then
        log INFO "Building bat theme cache..."
        bat cache --build &>/dev/null || log WARNING "Failed to build bat cache"
    fi
    
    # Set ZSH as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        log INFO "Setting ZSH as default shell..."
        chsh -s "$(which zsh)"
        log SUCCESS "Default shell changed to ZSH (restart your terminal)"
    fi
    
    log SUCCESS "ZSH environment configured"
}

# ============================================================================
# NEOVIM SETUP
# ============================================================================

setup_neovim() {
    log STEP "Setting up Neovim..."
    
    if ! command_exists nvim; then
        log INFO "Installing Neovim..."
        yay -S --noconfirm neovim
    fi
    
    # Install Node.js and npm for LSP servers
    if ! command_exists node; then
        log INFO "Installing Node.js..."
        yay -S --noconfirm nodejs npm
    fi
    
    # Install Python provider
    if ! command_exists python; then
        log INFO "Installing Python..."
        yay -S --noconfirm python python-pip
    fi
    
    # Install pynvim
    log INFO "Installing Python providers..."
    pip install --user pynvim 2>&1 | tee -a "$LOG_FILE" || true
    
    # Install language servers via Mason (will be done on first nvim launch)
    log INFO "Neovim plugins will be installed on first launch"
    
    log SUCCESS "Neovim configured"
}

# ============================================================================
# HYPRLAND AND WAYLAND SETUP
# ============================================================================

setup_hyprland() {
    log STEP "Setting up Hyprland environment..."
    
    # Ensure Hyprland is installed
    if ! command_exists Hyprland; then
        log INFO "Installing Hyprland..."
        yay -S --noconfirm hyprland
    fi
    
    # Install Hyprland ecosystem packages
    local hypr_packages=(
        "hyprpaper"           # Wallpaper daemon
        "hypridle"            # Idle daemon
        "hyprlock"            # Screen locker
        "hyprshot"            # Screenshot tool
        "hyprpicker"          # Color picker
        "xdg-desktop-portal-hyprland"
        "qt5-wayland"
        "qt6-wayland"
    )
    
    for pkg in "${hypr_packages[@]}"; do
        if ! package_installed "$pkg"; then
            log INFO "Installing $pkg..."
            yay -S --noconfirm "$pkg" 2>&1 | tee -a "$LOG_FILE" || log WARNING "Failed to install $pkg"
        fi
    done
    
    # Install Noctalia Shell (if available in AUR)
    if ! package_installed "noctalia-shell"; then
        log INFO "Installing Noctalia Shell..."
        yay -S --noconfirm noctalia-shell 2>&1 | tee -a "$LOG_FILE" || log WARNING "Noctalia Shell not found, may need manual installation"
    fi
    
    # Install Wayland utilities
    local wayland_utils=(
        "wl-clipboard"        # Clipboard utilities
        "wlroots"            # Wayland compositor library
        "waypaper"           # Wallpaper manager
        "brightnessctl"      # Brightness control
        "pamixer"            # Audio control
        "grim"               # Screenshot tool
        "slurp"              # Region selector
        "waybar"             # Status bar (alternative)
    )
    
    for util in "${wayland_utils[@]}"; do
        if ! package_installed "$util"; then
            yay -S --noconfirm "$util" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
    
    log SUCCESS "Hyprland environment configured"
}

# ============================================================================
# THEME AND APPEARANCE
# ============================================================================

setup_themes() {
    log STEP "Setting up themes and fonts..."
    
    # Install JetBrains Mono Nerd Font
    if ! fc-list | grep -qi "jetbrainsmono nerd font"; then
        log INFO "Installing JetBrains Mono Nerd Font..."
        yay -S --noconfirm nerd-fonts-jetbrains-mono
    else
        log INFO "JetBrains Mono Nerd Font already installed"
    fi
    
    # Install additional fonts
    local fonts=(
        "ttf-font-awesome"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-dejavu"
    )
    
    for font in "${fonts[@]}"; do
        if ! package_installed "$font"; then
            yay -S --noconfirm "$font" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
    
    # Refresh font cache
    log INFO "Refreshing font cache..."
    fc-cache -fv
    
    # Build bat theme cache for syntax highlighting
    if command_exists bat; then
        log INFO "Building bat theme cache..."
        bat cache --build &>/dev/null || log WARNING "Failed to build bat cache"
    fi
    
    # Install GTK and Qt themes
    log INFO "Installing theme packages..."
    local theme_packages=(
        "gtk3"
        "qt5ct"
        "kvantum"
        "bibata-cursor-theme"
    )
    
    for theme in "${theme_packages[@]}"; do
        if ! package_installed "$theme"; then
            yay -S --noconfirm "$theme" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
    
    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" 2>/dev/null || true
    
    log SUCCESS "Themes and fonts installed"
}

# ============================================================================
# POST-INSTALLATION
# ============================================================================

post_install() {
    log STEP "Running post-installation tasks..."
    
    # Create necessary directories
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Videos/Screencasts"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Documents"
    mkdir -p "$HOME/Projects"
    
    # Set proper permissions for scripts
    chmod +x "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true
    
    # Generate SSH key if not exists
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        if prompt_yes_no "Generate SSH key?"; then
            ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519"
            log SUCCESS "SSH key generated"
        fi
    fi
    
    log SUCCESS "Post-installation tasks completed"
}

# ============================================================================
# VALIDATION
# ============================================================================

validate_installation() {
    log STEP "Validating installation..."
    
    local errors=0
    
    # Check essential commands
    local essential_commands=(
        "zsh"
        "nvim"
        "tmux"
        "git"
        "stow"
        "fzf"
        "starship"
        "eza"
        "bat"
        "yazi"
        "lazygit"
        "Hyprland"
    )
    
    for cmd in "${essential_commands[@]}"; do
        if command_exists "$cmd"; then
            log INFO "✓ $cmd"
        else
            log ERROR "✗ $cmd not found"
            ((errors++))
        fi
    done
    
    # Check font installation
    if fc-list | grep -qi "jetbrainsmono nerd font"; then
        log INFO "✓ JetBrains Mono Nerd Font"
    else
        log ERROR "✗ JetBrains Mono Nerd Font not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log SUCCESS "All validations passed!"
    else
        log WARNING "$errors validation(s) failed. Check the log for details."
    fi
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              DOTFILES BOOTSTRAP SCRIPT                    ║
    ║                                                           ║
    ║  Environment: Arch Linux + Hyprland + Noctalia Shell     ║
    ║  Theme: Tokyo Night                                       ║
    ║  Shell: ZSH + Oh My Zsh + Starship                        ║
    ║  Font: JetBrains Mono Nerd Font                           ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_menu() {
    echo -e "\n${CYAN}Installation Options:${NC}"
    echo "1. Full installation (recommended)"
    echo "2. Custom installation (choose components)"
    echo "3. Exit"
    echo
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-packages)
                INSTALL_PACKAGES=false
                shift
                ;;
            --no-dotfiles)
                SETUP_DOTFILES=false
                shift
                ;;
            --no-shell)
                SETUP_SHELL=false
                shift
                ;;
            --no-nvim)
                SETUP_NVIM=false
                shift
                ;;
            --no-hyprland)
                SETUP_HYPRLAND=false
                shift
                ;;
            --no-themes)
                INSTALL_THEMES=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --no-packages    Skip package installation"
                echo "  --no-dotfiles    Skip dotfiles setup"
                echo "  --no-shell       Skip shell configuration"
                echo "  --no-nvim        Skip Neovim setup"
                echo "  --no-hyprland    Skip Hyprland setup"
                echo "  --no-themes      Skip theme installation"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

main() {
    # Initialize log file
    echo "Installation started at $(date)" > "$LOG_FILE"
    
    print_banner
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # System checks
    check_system
    
    # Show menu if running interactively without arguments
    if [ $# -eq 0 ] && [ -t 0 ]; then
        show_menu
        read -rp "$(echo -e "${CYAN}Select an option:${NC} ")" choice
        
        case $choice in
            1)
                log INFO "Starting full installation..."
                ;;
            2)
                prompt_yes_no "Install system packages?" && INSTALL_PACKAGES=true || INSTALL_PACKAGES=false
                prompt_yes_no "Setup dotfiles?" && SETUP_DOTFILES=true || SETUP_DOTFILES=false
                prompt_yes_no "Configure ZSH?" && SETUP_SHELL=true || SETUP_SHELL=false
                prompt_yes_no "Setup Neovim?" && SETUP_NVIM=true || SETUP_NVIM=false
                prompt_yes_no "Setup Hyprland?" && SETUP_HYPRLAND=true || SETUP_HYPRLAND=false
                prompt_yes_no "Install themes?" && INSTALL_THEMES=true || INSTALL_THEMES=false
                ;;
            3)
                log INFO "Installation cancelled"
                exit 0
                ;;
            *)
                error_exit "Invalid option"
                ;;
        esac
    fi
    
    # Confirm before proceeding
    echo
    log INFO "The following will be installed/configured:"
    $INSTALL_PACKAGES && echo "  • System packages"
    $INSTALL_AUR_HELPER && echo "  • AUR helper (yay)"
    $SETUP_DOTFILES && echo "  • Dotfiles (via GNU Stow)"
    $SETUP_SHELL && echo "  • ZSH with Oh My Zsh"
    $SETUP_NVIM && echo "  • Neovim configuration"
    $SETUP_HYPRLAND && echo "  • Hyprland + Noctalia Shell"
    $INSTALL_THEMES && echo "  • Themes and fonts"
    echo
    
    if ! prompt_yes_no "Continue with installation?"; then
        log INFO "Installation cancelled by user"
        exit 0
    fi
    
    # Run installation steps
    $INSTALL_AUR_HELPER && install_yay
    $INSTALL_PACKAGES && install_packages
    $SETUP_DOTFILES && setup_dotfiles
    $SETUP_SHELL && setup_zsh
    $SETUP_NVIM && setup_neovim
    $SETUP_HYPRLAND && setup_hyprland
    $INSTALL_THEMES && setup_themes
    
    # Post-installation
    post_install
    
    # Validate
    validate_installation
    
    # Final message
    echo
    log SUCCESS "═══════════════════════════════════════════════════════"
    log SUCCESS "Installation completed successfully!"
    log SUCCESS "═══════════════════════════════════════════════════════"
    echo
    log INFO "Next steps:"
    echo "  1. Restart your system or log out and log back in"
    echo "  2. Select Hyprland from your display manager"
    echo "  3. Open a terminal and verify the setup"
    echo "  4. Launch Neovim to install plugins: nvim"
    echo
    log INFO "Log file: $LOG_FILE"
    log INFO "Backup location: $BACKUP_DIR"
    echo
}

# Run main function
main "$@"
