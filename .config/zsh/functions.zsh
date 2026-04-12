# Load all function files from the functions directory
for func_file in "$ZSH_CONFIG_DIR/functions"/*.zsh; do
    source "$func_file"
done

sync-config() {
    if [ $# -ne 2 ]; then
        echo "Usage: sync-config <source> <target>"
        echo "Example: sync-config ~/.config/nvim ~/dot-files/.config/nvim.pack"
        return 1
    fi
    rsync -av --delete "$1/" "$2/"
}