# Vim mode: jk leaves insert mode, beam cursor in insert, block in normal
bindkey -v
KEYTIMEOUT=20
bindkey -M viins jk vi-cmd-mode
bindkey -M viins '^?' backward-delete-char '^h' backward-delete-char

_cursor() { [[ $KEYMAP == vicmd ]] && printf '\e[2 q' || printf '\e[6 q'; }
zle-keymap-select() { _cursor; }
zle-line-init() { _cursor; }
zle -N zle-keymap-select
zle -N zle-line-init

# v in normal mode: edit the command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Ctrl+k / Ctrl+j (and arrows): history search by the typed prefix
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^k' up-line-or-beginning-search '^[[A' up-line-or-beginning-search
bindkey '^j' down-line-or-beginning-search '^[[B' down-line-or-beginning-search

# Autosuggestions: Ctrl+e accept, Ctrl+w accept and run, Ctrl+u toggle
bindkey '^e' autosuggest-accept '^w' autosuggest-execute '^u' autosuggest-toggle
bindkey '^l' vi-forward-word

# Alt+s: toggle sudo in front of the line (or the previous command when empty)
_sudo() {
	[[ -z $BUFFER ]] && BUFFER="$(fc -ln -1)"
	if [[ $BUFFER == sudo\ * ]]; then BUFFER="${BUFFER#sudo }"; else BUFFER="sudo $BUFFER"; fi
	CURSOR=$#BUFFER
}
zle -N _sudo
bindkey '^[s' _sudo
