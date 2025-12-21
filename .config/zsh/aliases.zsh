# All command aliases

# ==============================
# Basic Aliases
# ==============================

alias rel='source ~/.zshrc'
alias cl='clear'
alias e='exit'
#
# ============================================================================
# FILE OPERATIONS
# ============================================================================
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'
alias rmf='rm -rf'

# ==============================
# Editor Aliases
# ==============================

alias vi='nvim'

# ==============================
# Development Tools
# ==============================

# Lazy tools
alias lg="lazygit"
alias ldc="lazydocker"

# Node.js
alias nrd='npm run dev'
alias ys='yarn start'
alias yd='yarn dev'

# ==============================
# Docker Aliases
# ==============================

alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias di="docker images"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# ==============================
# Git Aliases
# ==============================

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

# ==============================
# System Management
# ==============================

alias off='shutdown -h now'

# ==============================
# Clipboard Aliases
# ==============================

if [ "$WAYLAND_DISPLAY" ]; then
    alias c='wl-copy'
    alias v='wl-paste'
else
    alias c='xsel --input --clipboard'
    alias v='xsel --output --clipboard'
fi

# ==============================
# File Manager
# ==============================

alias y='yazi'

# ==============================
# System Info Tools
# ==============================

alias nf='neofetch'
alias ff='fastfetch'
alias pf='pfetch'

# ==============================
# TTY-based Fun Tools
# ==============================

alias tt='ttyper'
alias tc='tty-clock -t'
alias sl='sl --help -F -a'
alias p='pipes.sh'
alias cb='cbonsai -liv'
alias aq='asciiquarium'
alias cm='cmatrix -abs'

# ==============================
# TMUX Aliases
# ==============================

alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'

# ==============================
# Package Manager (Yay)
# ==============================

alias u='yay -Sy && yay -Syu -y'
alias i='yay -S'
alias r='yay -Rns'
alias s="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

# ==============================
# Directory Navigation
# ==============================

alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# ==============================
# Eza (Enhanced ls)
# ==============================

alias dir="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lsp="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user"
alias lsa="eza --color=always --long --git --icons=always -b -a --total-size"
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias tree="eza --tree --level=3 --icons --git"

# ==============================
# Network Manager
# ==============================

alias status='nmcli device status'
alias list='nmcli device wifi list'
alias connect='nmcli device wifi connect'
alias disconnect='nmcli device disconnect'

# ============================================================================
# SYSTEM INFO
# ============================================================================

alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias top='btop || htop || top'
alias mem='free -h && echo && ps aux | head -1 && ps aux | sort -rnk 4 | head -5'
alias cpu='ps aux | head -1 && ps aux | sort -rnk 3 | head -5'

# ============================================================================
# NETWORK
# ============================================================================

alias myip="hostname -I | awk '{print \$1}' && echo -n 'External: ' && curl -s ifconfig.me && echo"
alias ports='netstat -tulanp'
alias listening='lsof -P -i -n'

# ============================================================================
# DIRECTORY SHORTCUTS
# ============================================================================

alias g.='cd ~/.config'
alias gd='cd ~/Downloads'
alias gD='cd ~/Documents'
alias gs='cd ~/Pictures/Screenshots'
