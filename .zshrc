# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set Powerlevel10k as the theme.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of plugins to load.
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Set the autosuggestion highlight style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#c99e84'

# Always mkdir a path
alias mkdir='mkdir -p'

# Set nvim as default editor
export EDITOR='nvim'
export VISUAL='nvim'

# Alias for lazygit and lazydocker
alias lg='lazygit'
alias ld='lazydocker'

# Alias for clipboard
alias c='xsel --input --clipboard'
alias v='xsel --output --clipboard'

# Alias for neovim
alias nv='nvim'
alias nrd='npm run dev'

# Handy system management aliases
alias off='shutdown -h now'
alias cls='clear'
alias e='exit'

# Alias for yazi
alias y='yazi'

# Alias for fastfetch
alias ff='fastfetch'

# Alias for asciiquarium
alias aq='asciiquarium'

# TMUX aliases
alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'

# Zoxide alias
alias cd='z'

# GCC and Raylib aliases
alias gc='g++ -std=c++20 -o'
alias grc='g++ -std=c++20 -lraylib -lGL -lm -lpthread -ldl -lrt -lX11'

# Yay aliases
alias update='yay -Sy'
alias upgrade='yay -Syu'
alias install='yay -S'
alias remove='yay -Rs'
alias search='yay -Ss'

# Directory navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# History setup
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# Eza (better ls) aliases
alias dir="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsp="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user"
alias lsa="eza --color=always --long --git --icons=always -b -a --total-size"

# Initialize Zoxide
eval "$(zoxide init zsh)"

# FZF theme setup
export FZF_DEFAULT_OPTS="--color=fg:#CBE0F0,bg:#011628,hl:#B388FF,fg+:#CBE0F0,bg+:#143652,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED"

# Set Bat theme
export BAT_THEME=tokyonight_night

# NVM Initialization (Corrected)
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/share/nvm/init-nvm.sh" ] && source "/usr/share/nvm/init-nvm.sh"

# ttyper alias
alias tt='ttyper'

# tty-clock alias
alias tc='tty-clock -t'

# sl train alias
alias sl='sl --help -F -a'

# pipes.sh alias
alias p='pipes.sh'

# cbonsai alias
alias cb='cbonsai -liv'

# cmatrix alias
alias cm='cmatrix -absr'

# Network manager aliases
alias status='nmcli device status'
alias list='nmcli device wifi list'
alias connect='nmcli device wifi connect'
alias disconnect='nmcli device disconnect'

# Spicetify path
export PATH=$PATH:/home/ssk/.spicetify

# Go path
export PATH=$PATH:/home/ssk/go/bin/

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
