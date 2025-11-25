#!/bin/bash

set -e

ARCH_INSTALL_SCRIPT="$(pwd)/scripts/arch/install.sh"

echo "Installing packages for Arch Linux..."
bash "$ARCH_INSTALL_SCRIPT"
