#!/usr/bin/env bash

script_name="ff-logo-rotate"
target_dir="/usr/local/bin"
shell_config=""

# Check the shell type
if [[  "$SHELL" == *"zsh"  ]]; then
    shell_config="$HOME/.zshrc"
elif [[  "$SHELL" == *"bash"  ]]; then
    shell_config="$HOME/.bashrc"
else
    echo "Unsupported shell. Please add the alias manually."
    exit 1
fi

# Move the script to the target directory if it's not already there
if [ ! -f "$target_dir/$script_name" ]; then
    if sudo cp "$script_name" "/$target_dir/$script_name"; then
        echo "Script copied to $target_dir successfully."
    else
        echo "Failed to copy script to $target_dir. Please check permissions."
        exit 1
    fi
else
    echo "Script already exists in $target_dir. Skipping copy."
fi

# Make the script executable
sudo chmod +x "$target_dir/$script_name"

# Add alias to shell configuration if not already present
if grep -q 'alias ff=' "$shell_config"; then
    echo "An alias for 'ff' already exists in $shell_config."
    read -rp "Do you want to overwrite it? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # Remove the existing alias
        sed -i '/alias ff=/d' "$shell_config"
        echo "alias ff=ff-logo-rotate" >> "$shell_config"
        echo "Alias updated to use 'ff-logo-rotate'."
    else
        echo "Keeping the existing alias. You can manually run 'ff-logo-rotate' to use the script."
    fi
else
    echo "alias ff=ff-logo-rotate" >> "$shell_config"
    echo "Alias 'ff' added to $shell_config."
fi

echo "Installation complete. Please restart your terminal or run 'source $shell_config' to apply changes."
