# shellcheck shell=bash
# fzf options shared by bash and zsh. The legacy setup's look (fzf's own full layout, no border;
# matches in purple, prompt and pointer in cyan, the picked line on a soft highlight), in the
# terminal's palette numbers rather than fixed colours, so it follows the theme.
if command -v fd >/dev/null; then
	export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
fi
export FZF_DEFAULT_OPTS='--color=16,fg:7,fg+:7,bg+:8,hl:5,hl+:5,info:4,prompt:6,pointer:6,marker:6,spinner:6,header:6'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat {}' --preview-window=right:60%:wrap"
if command -v eza >/dev/null; then
	export FZF_ALT_C_OPTS="--preview 'LS_COLORS= eza -1a --icons --color=always --group-directories-first {}'"
else
	export FZF_ALT_C_OPTS="--preview 'ls -1A --color=always {}'"
fi
