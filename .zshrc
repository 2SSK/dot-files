# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable instant prompt to prevent consolve output warning
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of plugins to load
plugins=( git sudo zsh-autosuggestions zsh-syntax-highlighting )

source $ZSH/oh-my-zsh.sh

# Set nvim as defult editor
export EDITOR='nvim'
export VISUAL='nvim'

# Add custom aliases here
alias cls='clear'
alias lg='lazygit'
alias c='xsel --input --clipboard'
alias v='xsel --output --clipboard'
alias nv='nvim'
alias off='shutdown -h now'
alias e='exit'
alias y='yazi'
alias ff='fastfetch'

# TMUX alias
alias t='tmux'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tn='tmux new -s'
alias td='tmux detach'
alias cd='z'

# gcc compiler alias
alias gc='g++ -o'

# todo app alias
alias todo='~/Code/project/GO/go-todo-cli-app/./todo'

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
alias lsa="eza --color=always --long --git --no-filesize  --icons=always "

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

# Path to colorls
export PATH="$PATH:$HOME/.local/share/gem/ruby/3.0.0/bin"


[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
