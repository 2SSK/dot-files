#!/usr/bin/env bash

set -e

echo "[*] Detecting distribution..."

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Unsupported distro"
    exit 1
fi

echo "[+] Detected: $DISTRO"

install_packages() {
    echo "[*] Installing packages for $DISTRO..."

    case "$DISTRO" in
        arch)
            sudo pacman -Syu --noconfirm
            PKGS="zsh starship eza zoxide bat vim tmux"
            sudo pacman -S --noconfirm $PKGS
            ;;
        fedora)
            sudo dnf update -y
            sudo dnf install -y zsh starship eza zoxide bat vim-enhanced tmux git curl
            ;;
        ubuntu|debian)
            sudo apt update
            sudo apt install -y zsh curl git vim tmux
            # Install eza
            mkdir -p ~/.local/bin
            curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
                | grep "browser_download_url.*linux.*x86_64.*\.tar\.gz" \
                | cut -d '"' -f 4 | wget -qi - -O eza.tar.gz
            tar -xzf eza.tar.gz --strip-components=1 -C ~/.local/bin eza*/bin/eza
            chmod +x ~/.local/bin/eza
            rm -rf eza.tar.gz

            # Install bat
            sudo apt install -y bat || {
                curl -LO https://github.com/sharkdp/bat/releases/latest/download/bat_amd64.deb
                sudo dpkg -i bat_amd64.deb && rm bat_amd64.deb
            }

            # Install zoxide
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            # Install starship
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;
        *)
            echo "Unsupported distro: $DISTRO"
            exit 1
            ;;
    esac
}

setup_zsh() {
    echo "[*] Setting up Zsh and plugins..."

    # Set Zsh as default shell
    chsh -s "$(which zsh)"

    mkdir -p ~/.zsh

    # Zsh Autosuggestions
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

    # Zsh Syntax Highlighting
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

    # Zsh Config
    cat <<'EOF' > ~/.zshrc
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Zsh Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliases
alias ll='eza -la'
alias cat='bat'
EOF
}

setup_starship() {
    echo "[*] Setting up Starship prompt..."

    mkdir -p ~/.config
    cat <<'EOF' > ~/.config/starship.toml
# Customize as desired
add_newline = false

[character]
success_symbol = "[➜](bold green) "
error_symbol = "[✗](bold red) "
EOF
}

setup_vim() {
    echo "[*] Setting up Vim with vim-plug..."

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    cat <<'EOF' > ~/.vimrc
call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-sensible'
call plug#end()

syntax on
set number
colorscheme gruvbox
EOF

    vim +PlugInstall +qall
}

setup_tmux() {
    echo "[*] Setting up tmux with TPM..."

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    cat <<'EOF' > ~/.tmux.conf
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

run '~/.tmux/plugins/tpm/tpm'
EOF
}

install_packages
setup_zsh
setup_starship
setup_vim
setup_tmux

echo "[✓] Installation complete. Please restart your terminal or run \`exec zsh\`."
