# Core Configuration Directory
BASH_CONFIG_DIR="$HOME/.config/bash"

# Create config directory if it doesn't exist
[[ ! -d "$BASH_CONFIG_DIR" ]] && mkdir -p "$BASH_CONFIG_DIR"

# Source module files
source_if_exists(){
  [[ -f "$1" ]] && source "$1"
}

# Source modules in order
source_if_exists "$BASH_CONFIG_DIR/aliases.bash"
source_if_exists "$BASH_CONFIG_DIR/keybinds.bash"
source_if_exists "$BASH_CONFIG_DIR/prompt.bash"
source_if_exists "$BASH_CONFIG_DIR/functions/system.bash"
source_if_exists "$BASH_CONFIG_DIR/functions/utils.bash"
