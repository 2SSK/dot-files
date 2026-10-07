# shellcheck shell=sh
# Environment for every shell and the graphical session (sourced by .zshenv, .bashrc, .profile).
# POSIX sh, no subprocesses: it runs for every zsh, including scripts.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export EDITOR=nvim VISUAL=nvim SUDO_EDITOR=nvim
export TERMINAL=kitty
export PAGER=less LESS='-R --mouse' MANPAGER='nvim +Man!'
export BAT_THEME=ansi # follows the terminal palette
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

# Prepend existing dirs once; machine-specific paths belong in local.zsh / local.bash
for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$PNPM_HOME" "$HOME/.npm-global/bin"; do
	case ":$PATH:" in
	*":$dir:"*) ;;
	*) [ -d "$dir" ] && PATH="$dir:$PATH" ;;
	esac
done
unset dir
export PATH
