# ==============================
# Instant Prompt Configuration
# ==============================
# Enable Powerlevel10k instant prompt for faster shell startup.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ==============================
# Oh My Zsh & Theme Configuration
# ==============================
# Path to Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
#
# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

# Set the theme to Starship (overrides Powerlevel10k).
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# ==============================
# Locale Configuration
# ==============================
# Set default language and locale.
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
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

# ==============================
# Aliases
# ==============================

# Basic Aliases
alias mkdir='mkdir -p'
alias cls='clear'
alias e='exit'

# Editor Aliases
export EDITOR='nvim'
export VISUAL='nvim'
alias nv='nvim'

# Lazy aliases
alias lg="lazygit"
alias ld="lazydocker"

# Node.js Aliases
alias nrd='npm run dev'
alias ys='yarn start'
alias yd='yarn dev'

# Docker Aliases
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Git Aliases
alias gc="git commit"
alias gco="git commit -m"
alias gl="git log --oneline --graph"
alias gs="git status"

# System Management Aliases
alias off='shutdown -h now'

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
alias cm='cmatrix'

# TMUX Aliases
alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'

# Yay Package Manager Aliases
alias update='yay -Sy'
alias upgrade='yay -Syu'
alias install='yay -S'
alias remove='yay -Rns'
alias search='yay -Ss'

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
alias ltree="eza --tree --level=2 --icons --git"

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

# Bat Theme Setup
export BAT_THEME="gruvbox-dark"

# NVM Initialization
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/share/nvm/init-nvm.sh" ] && source "/usr/share/nvm/init-nvm.sh"

# Spicetify Path
export PATH=$PATH:/home/ssk/.spicetify

# Go Path
export PATH=$PATH:/home/ssk/go/bin/

# Android SDK Path
export ANDROID_HOME=/home/ssk/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Doom Emacs
alias doom='~/.emacs.d/bin/doom'
alias emacs="emacsclient -c -a 'emacs'"

# ==============================
# Zoxide Initialization
# ==============================
eval "$(zoxide init zsh)"
alias cd='z'

# ==============================
# Powerlevel10k Prompt
# ==============================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
