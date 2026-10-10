# shellcheck shell=bash
# Aliases shared by bash and zsh.

# eza when installed (icons, git column, tree), else coloured GNU ls; both in the terminal's
# colours, so they follow the theme.
if command -v eza >/dev/null; then
	alias ls='eza --group-directories-first --icons=auto'
	alias ll='ls -l --git' la='ll -a' lt='ls --tree --level=2' l='ls -la --git'
else
	alias ls='ls --color=auto --group-directories-first -h'
	alias ll='ls -l' la='ls -lA' l='ls -lA'
fi
alias dir='dir --color=auto' vdir='vdir --color=auto'
alias grep='grep --color=auto' diff='diff --color=auto' ip='ip -color=auto'

alias cp='cp -iv' mv='mv -iv' rm='rm -Iv' mkdir='mkdir -pv'
alias cl='clear' e='exit' rel='exec $SHELL'
alias vi='nvim' lg='lazygit' ldc='lazydocker' ff='fastfetch' tt='ttyper'
# no -u: with it, zsh's tmux completion took the flag for a subcommand ("subcommand -u not known"),
# and a UTF-8 locale gives tmux UTF-8 anyway
alias t='tmux' tl='tmux ls' ta='tmux attach -t' tn='tmux new -s' tk='tmux kill-session -t' td='tmux detach'
alias lazydocker='CONFIG_DIR="$XDG_STATE_HOME/desktop/theme/lazydocker" lazydocker' # config rendered from the theme
alias top='btop'
alias cava='cava -p "$XDG_STATE_HOME/desktop/theme/cava"' # config rendered from the theme

alias gs='git status --short' gd='git diff' gds='git diff --staged'
alias ga='git add' gap='git add --patch' gc='git commit' gp='git push' gu='git pull'
alias gb='git branch' gsw='git switch' gm='git merge' grb='git rebase' gr='git reset' gcl='git clone'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'

alias dco='docker compose' dps='docker ps' dpa='docker ps -a' dx='docker exec -it'

# yay for repo and AUR alike: u upgrades everything, i installs, r removes with unneeded deps
if command -v yay >/dev/null; then
	alias u='yay -Syu' i='yay -S' r='yay -Rns'
fi

if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
	alias c='wl-copy' v='wl-paste'
else
	alias c='xclip -selection clipboard' v='xclip -selection clipboard -o'
fi

alias ..='cd ..' ...='cd ../..'
alias g.='cd ~/.config' gD='cd ~/Documents' gS='cd ~/Pictures/Screenshots'

alias df='df -h' du='du -h' free='free -h' off='systemctl poweroff'
alias mem='free -h && echo && ps aux --sort=-%mem | head -6' cpu='ps aux --sort=-%cpu | head -6'
alias ports='ss -tulpn'
alias status='nmcli device status' list='nmcli device wifi list' connect='nmcli device wifi connect' disconnect='nmcli device disconnect'

alias weather='curl wttr.in/bengaluru?u'
alias tc='tty-clock -t' sl='sl --help -F -a' p='pipes.sh' cb='cbonsai -liv' aq='asciiquarium -t' cm='cmatrix -abs'
