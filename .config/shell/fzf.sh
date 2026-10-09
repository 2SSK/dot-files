# shellcheck shell=bash
# fzf options shared by bash and zsh. --color=16 uses the terminal's palette, so it follows the theme.
_fd="$(command -v fd || command -v fdfind)" # Debian names it fdfind
if [[ -n $_fd ]]; then
	export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --exclude .git"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND="$_fd --type d --hidden --exclude .git"
fi
unset _fd
export FZF_DEFAULT_OPTS='--color=16 --height=40% --layout=reverse --border=rounded --info=inline-right'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat {}'"
if command -v eza >/dev/null; then
	export FZF_ALT_C_OPTS="--preview 'LS_COLORS= eza -1a --icons --color=always --group-directories-first {}'"
else
	export FZF_ALT_C_OPTS="--preview 'ls -1A --color=always {}'"
fi
