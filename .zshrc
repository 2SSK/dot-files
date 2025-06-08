export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="robbyrussell"
#
# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

export LANG=en_IN.UTF-8
export LC_ALL=en_IN.UTF-8

# ==============================
# Plugins
# ==============================
plugins=(
  git
  sudo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Enable plugins and their features.
# source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#c99e84'
source $ZSH/oh-my-zsh.sh

# ==============================
# Key Bindings
# ==============================
bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^l' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

# ==============================
# Aliases
# ==============================

# Basic Aliases
alias mkdir='mkdir -p'
alias rmf='rm -rf'
alias cl='clear'
alias e='exit'

# Editor Aliases
export EDITOR='nvim'
export VISUAL='nvim'
alias vi='nvim'

# Lazy aliases
alias lg="lazygit"
alias ldc="lazydocker"

# Node.js Aliases
alias nrd='npm run dev'
alias ys='yarn start'
alias yd='yarn dev'

# Docker Aliases
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias di="docker images"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Git Aliases
alias gi="git init"
alias gcl="git clone"

alias gs="git status --short"
alias gd="git diff"
alias gds="gd --staged"

alias ga="git add"
alias gap="git add --patch"
alias gr="git reset"
alias gc="git commit"

alias gp="git push"
alias gu="git pull"

alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'
alias gb="git branch"

alias gm="git merge"
alias grb="git rebase"


alias gsw="git switch"
alias update-all-branches="git fetch origin && for branch in \$(git branch | sed 's/^\*//'); do git checkout \$branch && git merge main; done && git checkout main"

# System Management Aliases
alias off='shutdown -h now'

# Alias for clipboard
if [ "$WAYLAND_DISPLAY" ]; then
    alias c='wl-copy'
    alias v='wl-paste'
else
    alias c='xsel --input --clipboard'
    alias v='xsel --output --clipboard'
fi

# Yazi Alias
alias y='yazi'

# Fastfetch and Pfetch Aliases
alias nf='neofetch'
alias ff='fastfetch'
alias pf='pfetch'

# TTY-based Tools
alias tt='ttyper'
alias tc='tty-clock -t'
alias sl='sl --help -F -a'
alias p='pipes.sh'
alias cb='cbonsai -liv'
alias aq='asciiquarium'
alias cm='cmatrix -abs'

# TMUX Aliases
alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'

# Yay Package Manager Aliases
alias update='sudo dnf check-update'
alias upgrade='sudo dnf upgrade'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='dnf search'

# Directory Navigation Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# Eza (Enhanced ls) Aliases
alias dir="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsp="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user"
alias lsa="eza --color=always --long --git --icons=always -b -a --total-size"
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias tree="eza --tree --level=3 --icons --git"

# Network Manager Aliases
alias status='nmcli device status'
alias list='nmcli device wifi list'
alias connect='nmcli device wifi connect'
alias disconnect='nmcli device disconnect'

# ==============================
# Environment Variables
# ==============================

# History Settings
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# FZF Theme Setup
export FZF_DEFAULT_OPTS="--color=fg:#CBE0F0,bg:#011628,hl:#B388FF,fg+:#CBE0F0,bg+:#143652,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED"

# ==============================
# Zoxide Initialization
# ==============================
eval "$(zoxide init zsh)"
alias cd='z'

# Go Path
export PATH=$PATH:$HOME/go/bin

# Rust Path
export PATH="$HOME/.cargo/bin:$PATH"
