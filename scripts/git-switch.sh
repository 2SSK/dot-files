#!/bin/bash

set -eu 

SSH_DIR="$HOME/.ssh"
WORK_SSH_KEY="$SSH_DIR/work"
WORK_SSH_PUB_KEY="$SSH_DIR/work.pub"
PERSONAL_SSH_KEY="$SSH_DIR/personal"
PERSONAL_SSH_PUB_KEY="$SSH_DIR/personal.pub"

if [ "$#" -ne 1 ] || { [ "$1" != "work" ] && [ "$1" != "personal" ]; }; then
    echo "Usage: $0 [work|personal]"
    exit 1
fi

echo -e "Switching Git profile to \"\033[1m$1\033[0m\""

# Backup existing keys if they exist
[ -f "$SSH_DIR/id_rsa" ] && cp "$SSH_DIR/id_rsa" "$SSH_DIR/id_rsa.backup"
[ -f "$SSH_DIR/id_rsa.pub" ] && cp "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_rsa.pub.backup"

case "$1" in
    work)
        SRC_KEY="$WORK_SSH_KEY"
        SRC_PUB="$WORK_SSH_PUB_KEY"
        gh auth switch -u ssk-amoga
        ;;
    personal)
        SRC_KEY="$PERSONAL_SSH_KEY"
        SRC_PUB="$PERSONAL_SSH_PUB_KEY"
        gh auth switch -u 2SSK
        ;;
esac

# Check source files exist
if [ ! -f "$SRC_KEY" ] || [ ! -f "$SRC_PUB" ]; then
    echo "Error: Required SSH keys for '$1' not found."
    exit 1
fi

# Ensure SSH dir exists
mkdir -p "$SSH_DIR"

# Copy keys
cat "$SRC_KEY" > "$SSH_DIR/id_rsa"
cat "$SRC_PUB" > "$SSH_DIR/id_rsa.pub"

# Set permissions
chmod 600 "$SSH_DIR/id_rsa"
chmod 644 "$SSH_DIR/id_rsa.pub"

echo "SSH keys switched successfully. You may need to reload your SSH agent."
