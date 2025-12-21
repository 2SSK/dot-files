# Load all function files from the functions directory
for func_file in "$ZSH_CONFIG_DIR/functions"/*.zsh; do
    source "$func_file"
done
