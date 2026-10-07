# Init scripts are cached by cached_init (shell/functions.sh); delete ~/.cache/shell to refresh
cached_init dircolors.zsh dircolors -b
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

source "$XDG_CONFIG_HOME/shell/fzf.sh"
if [[ -t 0 ]]; then # fzf's widgets need a terminal
	cached_init fzf.zsh fzf --zsh
	# fzf binds Tab to its own completion; give it back to fzf-tab
	(( $+widgets[fzf-tab-complete] )) && bindkey '^I' fzf-tab-complete
fi
cached_init zoxide.zsh zoxide init zsh --cmd cd
cached_init starship.zsh starship init zsh
