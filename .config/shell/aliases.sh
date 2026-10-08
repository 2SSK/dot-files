# shellcheck shell=bash
# Aliases shared by bash and zsh.

# eza when installed (icons, git column, tree), else coloured GNU ls; both use LS_COLORS
if command -v eza >/dev/null; then
	alias ls='eza --group-directories-first --icons=auto'
	alias ll='ls -l --git' la='ll -a' lt='ls --tree --level=2'
else
	alias ls='ls --color=auto --group-directories-first -h'
	alias ll='ls -l' la='ls -lA'
fi
alias dir='dir --color=auto' vdir='vdir --color=auto'
alias grep='grep --color=auto' diff='diff --color=auto' ip='ip -color=auto'

alias cp='cp -iv' mv='mv -iv' rm='rm -Iv' mkdir='mkdir -pv'
alias cl='clear' e='exit' rel='exec $SHELL'
alias vi='nvim' lg='lazygit' ldc='lazydocker' ff='fastfetch' tt='ttyper'
# -u: always UTF-8, so icons render even when the locale lacks it (LANG=en_IN instead of en_IN.UTF-8)
alias tmux='tmux -u' t='tmux -u' tl='tmux ls' ta='tmux -u attach -t' tn='tmux -u new -s' tk='tmux kill-session -t' td='tmux detach'
alias lazydocker='CONFIG_DIR="$XDG_STATE_HOME/desktop/theme/lazydocker" lazydocker' # config rendered from the theme
alias top='btop'
alias cava='cava -p "$XDG_STATE_HOME/desktop/theme/cava"' # config rendered from the theme

alias gs='git status --short' gd='git diff' gds='git diff --staged'
alias ga='git add' gap='git add --patch' gc='git commit' gp='git push' gu='git pull'
alias gb='git branch' gsw='git switch' gm='git merge' grb='git rebase' gr='git reset' gcl='git clone'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'

alias dco='docker compose' dps='docker ps' dpa='docker ps -a' dx='docker exec -it'
alias nrd='npm run dev'
