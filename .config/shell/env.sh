# shellcheck shell=sh disable=SC1091 # /etc/locale.conf exists at runtime
# Environment for every shell and the graphical session (sourced by .zshenv, .bashrc, .profile).
# POSIX sh, no subprocesses: it runs for every zsh, including scripts.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Non-login shells (ssh commands, some terminals) miss the system locale; load it like a login shell would
if [ -z "${LANG:-}" ] && [ -r /etc/locale.conf ]; then
	. /etc/locale.conf
	export LANG
fi

export EDITOR=nvim VISUAL=nvim SUDO_EDITOR=nvim
export TERMINAL=kitty
export PAGER=less LESS='-R --mouse' MANPAGER='nvim +Man!'
export BAT_THEME=ansi # follows the terminal palette
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml" # explicit, so an inherited value (e.g. from an old tmux server) never wins
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export LG_CONFIG_FILE="$XDG_CONFIG_HOME/lazygit/config.yml,$XDG_STATE_HOME/desktop/theme/lazygit.yml"
# psql: coloured messages, and pspg as the pager with its theme rendered from the desktop palette
export PG_COLOR=auto PSQL_PAGER=pspg PSPG_CONF="$XDG_STATE_HOME/desktop/theme/pspg/pspgconf"
# opencode: the desktop theme (rendered by `theme`) lives in an extra config dir next to ~/.config/opencode
export OPENCODE_CONFIG_DIR="$XDG_STATE_HOME/desktop/theme/opencode"

# Prepend existing dirs once; machine-specific paths belong in local.zsh / local.bash
for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$PNPM_HOME" "$HOME/.npm-global/bin"; do
	case ":$PATH:" in
	*":$dir:"*) ;;
	*) [ -d "$dir" ] && PATH="$dir:$PATH" ;;
	esac
done
unset dir
export PATH
