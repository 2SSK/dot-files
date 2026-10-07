# Plugins are cloned into ./plugins by setup.sh (pinned in packages/plugins.txt)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

zstyle ':fzf-tab:*' switch-group '<' '>'
if (( $+commands[eza] )); then
	zstyle ':fzf-tab:complete:(cd|z|ls|ll|la|lt):*' fzf-preview 'eza -1a --icons --color=always --group-directories-first $realpath'
else
	zstyle ':fzf-tab:complete:(cd|z|ls|ll|la):*' fzf-preview 'ls -1A --color=always $realpath'
fi

# Syntax highlighting must be last: it wraps every widget defined before it
for _plugin in fzf-tab zsh-autosuggestions zsh-syntax-highlighting; do
	[[ -r $ZDOTDIR/plugins/$_plugin/$_plugin.plugin.zsh ]] &&
		source "$ZDOTDIR/plugins/$_plugin/$_plugin.plugin.zsh"
done
unset _plugin
