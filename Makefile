# Dotfiles Makefile
# Convenient commands for managing dotfiles

.PHONY: help install update backup clean validate stow unstow

# Default target
help:
	@echo "╔═══════════════════════════════════════════════════════╗"
	@echo "║           Dotfiles Management Commands                ║"
	@echo "╚═══════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available targets:"
	@echo "  make install      - Full installation (runs bootstrap.sh)"
	@echo "  make update       - Update system packages"
	@echo "  make backup       - Backup current dotfiles"
	@echo "  make stow         - Symlink dotfiles to home directory"
	@echo "  make unstow       - Remove dotfile symlinks"
	@echo "  make validate     - Check installation status"
	@echo "  make clean        - Remove backups and logs"
	@echo "  make help         - Show this help message"
	@echo ""

install:
	@echo "Starting full installation..."
	@./bootstrap.sh

install-packages:
	@echo "Installing packages only..."
	@./bootstrap.sh --no-dotfiles --no-shell --no-nvim --no-hyprland --no-themes

install-dotfiles:
	@echo "Installing dotfiles only..."
	@./bootstrap.sh --no-packages

update:
	@echo "Updating system packages..."
	@yay -Syu

backup:
	@echo "Creating backup of current dotfiles..."
	@mkdir -p ~/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)
	@cp -r ~/.config ~/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
	@cp ~/.zshrc ~/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
	@cp ~/.tmux.conf ~/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
	@echo "Backup created in ~/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)"

stow:
	@echo "Stowing dotfiles..."
	@stow --restow --target=$(HOME) --verbose=1 .

unstow:
	@echo "Unstowing dotfiles..."
	@stow --delete --target=$(HOME) --verbose=1 .

validate:
	@echo "Validating installation..."
	@echo ""
	@echo "Checking essential commands:"
	@command -v zsh >/dev/null 2>&1 && echo "✓ zsh" || echo "✗ zsh"
	@command -v nvim >/dev/null 2>&1 && echo "✓ nvim" || echo "✗ nvim"
	@command -v tmux >/dev/null 2>&1 && echo "✓ tmux" || echo "✗ tmux"
	@command -v git >/dev/null 2>&1 && echo "✓ git" || echo "✗ git"
	@command -v stow >/dev/null 2>&1 && echo "✓ stow" || echo "✗ stow"
	@command -v fzf >/dev/null 2>&1 && echo "✓ fzf" || echo "✗ fzf"
	@command -v eza >/dev/null 2>&1 && echo "✓ eza" || echo "✗ eza"
	@command -v bat >/dev/null 2>&1 && echo "✓ bat" || echo "✗ bat"
	@command -v yazi >/dev/null 2>&1 && echo "✓ yazi" || echo "✗ yazi"
	@command -v lazygit >/dev/null 2>&1 && echo "✓ lazygit" || echo "✗ lazygit"
	@command -v Hyprland >/dev/null 2>&1 && echo "✓ Hyprland" || echo "✗ Hyprland"
	@command -v starship >/dev/null 2>&1 && echo "✓ starship" || echo "✗ starship"
	@echo ""
	@echo "Checking fonts:"
	@fc-list | grep -qi "jetbrainsmono nerd font" && echo "✓ JetBrains Mono Nerd Font" || echo "✗ JetBrains Mono Nerd Font"
	@echo ""

clean:
	@echo "Cleaning up..."
	@rm -f install.log
	@rm -rf .stow-local-ignore~
	@echo "Cleaned logs and temporary files"

clean-backups:
	@echo "Removing old backups..."
	@rm -rf ~/.dotfiles-backup-*
	@echo "Backups removed"

nvim-clean:
	@echo "Cleaning Neovim data (plugins will reinstall)..."
	@rm -rf ~/.local/share/nvim
	@rm -rf ~/.local/state/nvim
	@rm -rf ~/.cache/nvim
	@echo "Neovim cleaned. Plugins will reinstall on next launch."

git-setup:
	@echo "Setting up Git configuration..."
	@read -p "Enter your name: " name && git config --global user.name "$$name"
	@read -p "Enter your email: " email && git config --global user.email "$$email"
	@echo "Git configured!"

ssh-keygen:
	@echo "Generating SSH key..."
	@read -p "Enter your email: " email && ssh-keygen -t ed25519 -C "$$email"
	@echo "SSH key generated!"
	@echo "Add this to GitHub:"
	@cat ~/.ssh/id_ed25519.pub

test:
	@echo "Running configuration tests..."
	@bash -n bootstrap.sh && echo "✓ bootstrap.sh syntax OK" || echo "✗ bootstrap.sh syntax error"
	@bash -n arch/install.sh && echo "✓ arch/install.sh syntax OK" || echo "✗ arch/install.sh syntax error"
	@bash -n scripts/*.sh 2>/dev/null && echo "✓ scripts/*.sh syntax OK" || echo "✗ scripts syntax error"
	@echo "Tests complete"

info:
	@echo "Dotfiles Repository Information"
	@echo "==============================="
	@echo "Location: $$(pwd)"
	@echo "Files: $$(find . -type f | wc -l)"
	@echo "Directories: $$(find . -type d | wc -l)"
	@echo "Last update: $$(git log -1 --format=%cd --date=short 2>/dev/null || echo 'N/A')"
	@echo "Git branch: $$(git branch --show-current 2>/dev/null || echo 'N/A')"
