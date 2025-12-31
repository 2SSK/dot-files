export ZSH="$HOME/.oh-my-zsh"

# ==============================
# Core Configuration Directory
# ==============================
ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Create config directory if it doesn't exist
[[ ! -d "$ZSH_CONFIG_DIR" ]] && mkdir -p "$ZSH_CONFIG_DIR"

# ==============================
# Load Configuration Modules
# ==============================

# Source module files
source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Load modules in order
source_if_exists "$ZSH_CONFIG_DIR/options.zsh"      # ZSH options and settings
source_if_exists "$ZSH_CONFIG_DIR/completion.zsh"   # Completion settings
source_if_exists "$ZSH_CONFIG_DIR/plugins.zsh"      # Plugin configuration
source_if_exists "$ZSH_CONFIG_DIR/prompt.zsh"       # Prompt configuration
source_if_exists "$ZSH_CONFIG_DIR/keybindings.zsh"  # Key bindings
source_if_exists "$ZSH_CONFIG_DIR/aliases.zsh"      # All aliases
source_if_exists "$ZSH_CONFIG_DIR/env.zsh"          # Environment variables
source_if_exists "$ZSH_CONFIG_DIR/paths.zsh"        # PATH configurations
source_if_exists "$ZSH_CONFIG_DIR/functions.zsh"    # Custom functions
source_if_exists "$ZSH_CONFIG_DIR/tools.zsh"        # External tools (fzf, zoxide, etc)

# Load local overrides (gitignored personal settings)
source_if_exists "$ZSH_CONFIG_DIR/local.zsh"
