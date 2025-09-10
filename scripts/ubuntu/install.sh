#!/bin/bash
set -e

PACKAGES_TO_INSTALL="$(pwd)/scripts/ubuntu/packages.txt"

echo ""
echo "Starting Ubuntu installation script..."
echo "-------------------------------------"

install_packages_ubuntu() {
  if [ ! -f "$PACKAGES_TO_INSTALL" ]; then
    echo "Package list file not found: $PACKAGES_TO_INSTALL"
    exit 1
  fi

  while read -r pkg source; do
    # skip empty lines or comments
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

    case "$source" in
    apt)
      if dpkg -s "$pkg" &>/dev/null; then
        echo "$pkg is already installed (apt)."
      else
        echo "Installing $pkg via apt..."
        sudo apt-get install -y "$pkg"
      fi
      ;;
    snap)
      echo "⚠ Skipping $pkg via snap (snap may be outdated or missing)."
      ;;
    manual)
      case "$pkg" in
      starship)
        if command -v starship &>/dev/null; then
          echo "starship is already installed."
        else
          echo "Installing starship via official script..."
          curl -sS https://starship.rs/install.sh | sh
        fi
        ;;
      neovim)
        if command -v nvim &>/dev/null; then
          echo "Neovim is already installed."
        else
          echo "Installing bleeding-edge Neovim..."
          # install dependencies
          sudo apt-get install -y software-properties-common
          # add Neovim unstable PPA
          sudo add-apt-repository -y ppa:neovim-ppa/unstable
          sudo apt-get update
          sudo apt-get install -y neovim
        fi
        ;;
      *)
        echo "⚠ $pkg requires manual installation (not available via apt/snap)."
        ;;
      esac
      ;;
    *)
      echo "Unknown source for $pkg. Skipping."
      ;;
    esac

  done <"$PACKAGES_TO_INSTALL"
}

setup_environment_ubuntu() {
  echo ""
  echo "Setting up environment for Ubuntu..."
  echo "-----------------------------------"

  # zsh default shell
  if command -v zsh &>/dev/null && [[ "$SHELL" != *"zsh" ]]; then
    chsh -s "$(command -v zsh)"
    echo "Default shell set to zsh."
  fi

  # stow dotfiles
  DOTFILES_DIR="$(pwd)"
  [ -d "$DOTFILES_DIR" ] && command -v stow &>/dev/null &&
    stow --dir="$DOTFILES_DIR" --target="$HOME" * &&
    echo "Dotfiles stowed."

  # make sure wget and unzip are installed
  sudo apt-get install -y wget unzip

  # JetBrains Mono Nerd Font (manual fallback)
  if fc-list | grep -qi "jetbrainsmono nerd font"; then
    echo "JetBrains Mono Nerd Font already installed."
  else
    echo "Installing JetBrains Mono Nerd Font..."
    wget -qO /tmp/jetbrainsmono.zip \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o /tmp/jetbrainsmono.zip -d ~/.local/share/fonts/
    fc-cache -fv
    rm /tmp/jetbrainsmono.zip
    echo "JetBrains Mono Nerd Font installed."
  fi
}

# update apt first
sudo apt-get update

install_packages_ubuntu
setup_environment_ubuntu
