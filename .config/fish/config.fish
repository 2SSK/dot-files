# ==============================
# Fish Greeting (disable default greeting)
# ==============================
# set -g fish_greeting

# ==============================
# Starship Prompt Initialization
# ==============================
if status is-interactive
    starship init fish | source
end

# ==============================
# Aliases and Abbreviations
# ==============================

# Directory listing aliases using eza
alias l='eza -lh --icons=auto' # long list
alias ls='eza -1 --icons=auto'          # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto'        # long list dirs
alias lt='eza --icons=auto --tree'      # list folder as tree

# Handy change dir shortcuts (abbr = abbreviation)
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Basic Aliases
abbr mkdir 'mkdir -p'
abbr cl 'clear'
abbr e 'exit'

# Editor Aliases
set -x EDITOR nvim
set -x VISUAL nvim
abbr vi 'nvim'

# Lazy aliases
abbr lg 'lazygit'
abbr ldc 'lazydocker'

# Node.js Aliases
abbr nrd 'npm run dev'
abbr ys 'yarn start'
abbr yd 'yarn dev'

# Docker Aliases
abbr dco 'docker compose'
abbr dps 'docker ps'
abbr dpa 'docker ps -a'
abbr di 'docker images'
abbr dl 'docker ps -l -q'
abbr dx 'docker exec -it'

# Git Aliases
abbr gs 'git status'
abbr gb 'git branch'
abbr gsw 'git switch'
abbr ga 'git add .'
abbr gr 'git reset'
abbr gc 'git commit'
abbr gco 'git commit -m'
abbr gp 'git push'
abbr gl 'git log --oneline --graph'
abbr gm 'git merge'
abbr grb 'git rebase'
abbr update-all-branches 'git fetch origin; for branch in (git branch | sed "s/^\*//"); echo "Updating $branch"; git checkout $branch; git merge main; end; git checkout main'

# System Management Aliases
abbr off 'shutdown -h now'

# Clipboard Aliases (Wayland vs X11)
if set -q WAYLAND_DISPLAY
    abbr c 'wl-copy'
    abbr v 'wl-paste'
else
    abbr c 'xsel --input --clipboard'
    abbr v 'xsel --output --clipboard'
end

# Compilation Aliases
abbr cmp 'g++ -std=c++20 -o'
abbr grc 'g++ -std=c++20 -lraylib -lGL -lm -lpthread -ldl -lrt -lX11'

# Yazi Alias
abbr y 'yazi'

# Fastfetch and Pfetch Aliases
abbr nf 'neofetch'
abbr ff 'fastfetch'
abbr pf 'pfetch'

# TTY-based Tools
abbr tt 'ttyper'
abbr tc 'tty-clock -t'
abbr sl 'sl --help -F -a'
abbr p 'pipes.sh'
abbr cb 'cbonsai -liv'
abbr aq 'asciiquarium'
abbr cm 'cmatrix -a -b -s'

# TMUX Aliases
abbr t 'tmux'
abbr tl 'tmux ls'
abbr ta 'tmux attach -t'
abbr tk 'tmux kill-session -t'
abbr tn 'tmux new -s'
abbr td 'tmux detach'

# Yay Package Manager Aliases
abbr update 'yay -Sy'
abbr upgrade 'yay -Syu'
abbr install 'yay -S'
abbr remove 'yay -Rns'
abbr search 'yay -Ss'

# Directory Navigation Aliases (already covered by abbr above)

# Eza (Enhanced ls) Aliases (redundant with above but included for completeness)
abbr dir "eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
abbr ls "eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
abbr lsp "eza --color=always --long --git --no-filesize --icons=always --no-time --no-user"
abbr lsa "eza --color=always --long --git --icons=always -b -a --total-size"
abbr l "eza -l --icons --git -a"
abbr lt "eza --tree --level=2 --long --icons --git"
abbr tree "eza --tree --level=3 --icons --git"

# Network Manager Aliases
abbr status 'nmcli device status'
abbr list 'nmcli device wifi list'
abbr connect 'nmcli device wifi connect'
abbr disconnect 'nmcli device disconnect'

# Doom Emacs Aliases
abbr doom '~/.emacs.d/bin/doom'
abbr emacs "emacsclient -c -a 'emacs'"

# Go Aliases
abbr gn 'go run'
abbr task 'go-task'

# Python Aliases
abbr mkvenv 'python -m venv venv; source venv/bin/activate'

# ==============================
# Environment Variables
# ==============================

# Locale
set -x LANG en_IN.UTF-8
set -x LC_ALL en_IN.UTF-8

# History Settings (Fish handles history differently, but you can tweak it)
# Fish automatically shares history between sessions

# FZF Theme Setup
set -x FZF_DEFAULT_OPTS '--color=fg:#CBE0F0,bg:#011628,hl:#B388FF,fg+:#CBE0F0,bg+:#143652,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED'

# Bat Theme Setup
set -x BAT_THEME tokyonight_night

# Spicetify Path
set -x PATH $PATH /home/ssk/.spicetify

# Go Path
set -x PATH $PATH /home/ssk/go/bin/

# Android SDK Path
set -x ANDROID_HOME /home/ssk/Android/Sdk
set -x PATH $PATH $ANDROID_HOME/tools $ANDROID_HOME/platform-tools

# ==============================
# Fzf Directory Finder Function
# ==============================
function fd
    set -l selection (find . -type d -readable 2>/dev/null | fzf --preview 'exa -la --color=always {}')
    if test -d "$selection"
        cd "$selection"
    end
end

# ==============================
# Key Bindings (Translated from Zsh)
# ==============================

# Accept autosuggestion (Ctrl+E)
bind \ce accept-autosuggestion

# Execute autosuggestion (Ctrl+W) - custom function
function autosuggest_execute
    commandline -f accept-autosuggestion
    commandline -f execute
end
bind \cw autosuggest_execute

# Toggle autosuggestion (Ctrl+U)
function autosuggest_toggle
    if set -q fish_autosuggestion_enabled
        set -e fish_autosuggestion_enabled
        echo "Fish autosuggestion disabled"
    else
        set -g fish_autosuggestion_enabled 1
        echo "Fish autosuggestion enabled"
    end
end
bind \cu autosuggest_toggle

# Move forward by word (Ctrl+L)
bind \cl forward-word

# Up-line-or-search (Ctrl+K)
bind \ck up-or-search

# Down-line-or-search (Ctrl+J)
bind \cj down-or-search

