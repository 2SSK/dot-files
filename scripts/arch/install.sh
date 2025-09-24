#!/bin/bash

set -e

PACKAGES_TO_INSTALL="$(pwd)/scripts/arch/packages.txt"

echo ""
echo "Starting installation script..."
echo "-------------------------------"

check_yay_installed() {
  if command -v yay &>/dev/null; then
    echo "yay is already installed."
  else
    echo "yay is not installed. Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
    echo "yay installation completed."
  fi
}

install_packages_arch() {
  echo ""
  echo "Installing packages for Arch Linux..."
  echo "-------------------------------------"

  check_yay_installed

  if [ -f "$PACKAGES_TO_INSTALL" ]; then
    while IFS= read -r package; do
      # skip empty lines and comments
      [[ -z "$package" || "$package" =~ ^# ]] && continue

      if pacman -Qi "$package" &>/dev/null || yay -Qi "$package" &>/dev/null; then
        echo "$package is already installed."
      else
        echo "Installing $package..."
        if yay -S --noconfirm "$package"; then
          echo "$package installation completed."
        else
          echo "Failed to install $package."
        fi
      fi
    done <"$PACKAGES_TO_INSTALL"
  else
    echo "Package list file not found: $PACKAGES_TO_INSTALL"
    exit 1
  fi
}

setup_environment_arch() {
  echo ""
  echo "Setting up environment for Arch Linux..."
  echo "---------------------------------------"

  # Set zsh as default shell
  if command -v zsh &>/dev/null && [[ "$SHELL" != *"zsh" ]]; then
    chsh -s "$(command -v zsh)"
    echo "Default shell set to zsh."
  fi

  # Stow dotfiles
  DOTFILES_DIR="$(pwd)"
  [ -d "$DOTFILES_DIR" ] && command -v stow &>/dev/null &&
    stow --dir="$DOTFILES_DIR" --target="$HOME" * &&
    echo "Dotfiles stowed."

  # Ensure JetBrains Mono Nerd Font
  fc-list | grep -qi "jetbrainsmono nerd font" ||
    yay -S --noconfirm nerd-fonts-jetbrains-mono

  echo "Environment setup completed."
}

install_packages_arch
setup_environment_arch
