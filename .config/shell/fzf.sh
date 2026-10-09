# shellcheck shell=bash
# fzf options shared by bash and zsh: minimal, no frame, a slim pointer, matches in the accent.
# --color=16 and ANSI numbers use the terminal's palette, so it follows the theme.
_fd="$(command -v fd || command -v fdfind)" # Debian names it fdfind
if [[ -n $_fd ]]; then
	export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --exclude .git"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND="$_fd --type d --hidden --exclude .git"
fi
unset _fd
export FZF_DEFAULT_OPTS="--color=16,fg+:-1:bold,bg+:-1,gutter:-1,hl:4,hl+:4:bold,pointer:4,marker:5,prompt:4,spinner:4,info:8,border:8,scrollbar:8,preview-border:8 \
--height=45% --layout=reverse --border=none --padding=1,2 --info=inline-right --no-separator \
--prompt='❯ ' --pointer='▌' --marker='▍' --scrollbar='▏' --preview-window='right,55%,border-left'"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat {}'"
if command -v eza >/dev/null; then
	export FZF_ALT_C_OPTS="--preview 'LS_COLORS= eza -1a --icons --color=always --group-directories-first {}'"
else
	export FZF_ALT_C_OPTS="--preview 'ls -1A --color=always {}'"
fi
