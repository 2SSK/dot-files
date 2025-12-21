# External tool configurations

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

# ==============================
# Zoxide Initialization
# ==============================

eval "$(zoxide init zsh)"
alias cd='z'
