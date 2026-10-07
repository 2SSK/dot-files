# shellcheck shell=bash
# Aliases shared by bash and zsh.

# Colour from the tools' own defaults (LS_COLORS comes from dircolors, see tools)
alias ls='ls --color=auto --group-directories-first -h'
alias ll='ls -l' la='ls -lA'
alias dir='dir --color=auto' vdir='vdir --color=auto'
alias grep='grep --color=auto' diff='diff --color=auto' ip='ip -color=auto'

alias cp='cp -iv' mv='mv -iv' rm='rm -Iv' mkdir='mkdir -pv'
alias cl='clear' e='exit' rel='exec $SHELL'
alias vi='nvim' t='tmux' y='yazi' lg='lazygit' ldc='lazydocker' ff='fastfetch'
alias top='btop'

alias gs='git status --short' gd='git diff' gds='git diff --staged'
alias ga='git add' gap='git add --patch' gc='git commit' gp='git push' gu='git pull'
alias gb='git branch' gsw='git switch' gm='git merge' grb='git rebase' gr='git reset' gcl='git clone'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'

alias dco='docker compose' dps='docker ps' dpa='docker ps -a' dx='docker exec -it'
alias nrd='npm run dev'
