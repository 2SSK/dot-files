autoload -Uz compinit

# Full compinit (security check + dump) at most once a day; otherwise load the dump
_dump="$XDG_CACHE_HOME/zsh/zcompdump"
[[ -d ${_dump:h} ]] || mkdir -p "${_dump:h}"
_fresh=("$_dump"(N.mh-24))
if (( $#_fresh )); then compinit -C -d "$_dump"; else compinit -d "$_dump"; fi
unset _dump _fresh

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no # fzf-tab draws the menu
