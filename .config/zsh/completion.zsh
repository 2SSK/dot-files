# Completion system configuration

# ==============================
# Completion Settings
# ==============================

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit
