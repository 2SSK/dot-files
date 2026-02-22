# External tool configurations
#
# ==============================
# Zoxide Initialization
# ==============================

eval "$(zoxide init zsh)"
alias cd='z'

# ==============================
# FZF Configuration
# ==============================

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# FZF theme
fg="#a9b1d6"
bg="#1a1b26"
bg_highlight="#444b6a"
purple="#bb9af7"
blue="#7da6ff"
cyan="#0db9d7"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"


# Preview for files (use bat if available)
if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {}' --preview-window=right:60%:wrap"
else
    export FZF_CTRL_T_OPTS="--preview 'head -300 {}' --preview-window=right:60%:wrap"
fi

export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"

# Fuzzy cd into a directory
fcd() {
    local dir
    dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m --prompt="cd> ")
    [[ -n "$dir" ]] && cd "$dir"
}

# Fuzzy search command history
fhist() {
    local cmd
    cmd=$(history | fzf --tac --prompt="Hist> " | sed 's/ *[0-9]* *//')
    [[ -n "$cmd" ]] && eval "$cmd"
}

# Fuzzy kill process
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --prompt="Kill> " | awk '{print $2}')
    [[ -n "$pid" ]] && kill -9 $pid
}

# Alias for fcd
fd() { fcd "$1"; }

# Fuzzy find file
ffind() {
    local file
    file=$(find "${1:-.}" -type f 2>/dev/null | fzf --prompt="Find> ")
    [[ -n "$file" ]] && echo "$file"
}

# Fuzzy file editor
fedit() {
    local files
    local editor="${EDITOR:-vim}"

    # Select one or more files
    files=$(fzf -m --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}' --preview-window=right:50%:wrap --prompt="Edit> ")

    if [[ -n "$files" ]]; then
        # Handle multiple files (one per line)
        echo "$files" | while read -r file; do
            if [[ -n "$file" ]]; then
                $editor "$file"
            fi
        done
    fi
}

# Fuzzy man page search
fman() {
    local man_page
    man_page=$(man -k . | fzf --prompt='Man> ' | awk '{print $1}')

    if [[ -n "$man_page" ]]; then
        man "$man_page"
    fi
}

# Fuzzy SSH host selection
fssh() {
    local host
    host=$(grep "^Host " ~/.ssh/config 2>/dev/null | grep -v "*" | awk '{print $2}' | fzf --prompt="SSH> ")

    if [[ -n "$host" ]]; then
        ssh "$host"
    fi
}

# Fuzzy environment variable search
fenv() {
    local var
    var=$(env | fzf --height 40% --prompt="Env> " --preview 'echo {} | cut -d= -f2')

    if [[ -n "$var" ]]; then
        echo "$var" | cut -d= -f1 | tr -d '\n' | xclip -selection clipboard 2>/dev/null
        echo "Copied to clipboard: $(echo "$var" | cut -d= -f1)"
    fi
}

# Fuzzy grep with ripgrep
fzf_grep() {
    local pattern="${1:-}"
    local file

    if [[ -z "$pattern" ]]; then
        echo "Usage: fzf_grep <pattern>"
        return 1
    fi

    if command -v rg >/dev/null 2>&1; then
        file=$(rg --line-number --color=never --no-heading --smart-case "$pattern" 2>/dev/null |
               fzf --delimiter=: --nth=1..2 \
                   --preview 'bat --style=numbers --color=always {1} 2>/dev/null | grep -C 3 --color=always {2}' \
                   --preview-window=right:50%:wrap \
                   --prompt="Grep> " \
                   --bind="ctrl-o:execute($EDITOR +{2} {1})+abort")
        if [[ -n "$file" ]]; then
            local line=$(echo "$file" | cut -d: -f2)
            file=$(echo "$file" | cut -d: -f1)
            ${EDITOR:-vim} +"$line" "$file"
        fi
    else
        echo "ripgrep (rg) is required for fzf_grep"
        return 1
    fi
}

# Fuzzy git log browser
fgl() {
    git log --oneline --graph --color=always | \
        fzf --ansi --no-sort --reverse --prompt="Git Log> " \
            --preview 'git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1)' \
            --preview-window=right:60%:wrap \
            --bind 'enter:execute(git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1) | less -R)'
}

# Fuzzy docker container exec
fdex() {
    local container
    container=$(docker ps --format '{{.Names}}' 2>/dev/null | fzf --prompt="Container> ") || return
    
    if [[ -n "${container}" ]]; then
        docker exec -it "${container}" "${1:-/bin/bash}"
    fi
}

# Fuzzy docker logs
fdlogs() {
    local container
    container=$(docker ps -a --format '{{.Names}}' 2>/dev/null | fzf --prompt="Logs> ") || return
    
    if [[ -n "${container}" ]]; then
        docker logs -f "${container}"
    fi
}

# Fuzzy systemd unit browser
fsc() {
    local unit
    unit=$(systemctl list-units --all --no-pager | sed 1d | \
        fzf --prompt="Systemd> " | awk '{print $1}') || return
    
    if [[ -n "${unit}" ]]; then
        systemctl status "${unit}"
    fi
}
