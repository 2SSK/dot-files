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

# In tmux, before each command: the display variables of the session the client attached from
# (tmux updates them on attach, but a shell started under i3 keeps i3's: DISPLAY=:0 is then the
# login screen's X server under sway, and X answers "Authorization required")
if [[ -n $TMUX ]]; then
	_tmux_session_env() {
		local line
		for line in "${(@f)$(tmux show-environment -s 2>/dev/null)}"; do
			[[ $line == (unset |)(DISPLAY|WAYLAND_DISPLAY|XAUTHORITY|SWAYSOCK|I3SOCK|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE)[=\;]* ]] && eval "$line"
		done
	}
	autoload -Uz add-zsh-hook
	add-zsh-hook preexec _tmux_session_env
fi
