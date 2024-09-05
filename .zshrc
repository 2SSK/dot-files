# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable instant prompt to prevent consolve output warning
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
# ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME="cloud"

# Set list of plugins to load
plugins=( git sudo zsh-autosuggestions zsh-syntax-highlighting )
source $ZSH/oh-my-zsh.sh

# Set the autosuggestion highlight style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#c99e84'  

# Always mkdir a path 
alias mkdir='mkdir -p'

# Set nvim as defult editor
export EDITOR='nvim'
export VISUAL='nvim'

# Alias for lazygit
alias lg='lazygit'

# Alias for clipboard
alias c='xsel --input --clipboard'
alias v='xsel --output --clipboard'

# Alias for neovim
alias nv='nvim'
alias nrd='npm run dev'

# Alias for most used commands
alias off='shutdown -h now'
alias cls='clear'
alias e='exit'

# Alias for yazi
alias y='yazi'

# Alias for fastfetch
alias ff='fastfetch'

# Alias for asciiquarium
alias aq='asciiquarium'

# TMUX alias
alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'

# Zoxide alias
alias cd='z'

# gcc compiler alias
alias gc='g++ -std=c++20 -o'

# System alias
alias update='sudo pacman -Sy'
alias upgrade='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rs'
alias search='pacman -Ss'

# yay alias
alias yd='yay -Sy'
alias yg='yay -Syu'
alias yi='yay -S'
alias yr='yay -Rs'
alias ys='yay -Ss'

# Handy change dir shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# history setup
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# ---- Eza (better ls) -----
alias dir="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsp="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user"
alias lsa="eza --color=always --long --git  --icons=always -b -a --total-size "

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# --- Bat (bettter cat) ---
export BAT_THEME=tokyonight_night

# Path variable
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# rofimoji path
export PATH="/usr/bin/rofimoji:$PATH"

# ttyper 
alias tt='ttyper'

# tty-clock
alias tc='tty-clock -t'
# sl train 
alias sl='sl --help -F -a'
# pipe.sh
alias p='pipes.sh'
# cbonsai
alias cb='cbonsai -liv'
# cmatrix
alias cm='cmatrix -absr'

# alias for network manager
alias status='nmcli device status'
alias list='nmcli device wifi list'
alias connect='nmcli device wifi connect'
alias disconnect='nmcli device disconnect'

export PATH=$PATH:/home/ssk/.spicetify

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

