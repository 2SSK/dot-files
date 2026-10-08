# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091 # sources runtime paths under $XDG_CONFIG_HOME
# Interactive bash, kept simple: the shared environment, aliases and functions, history and
# starship. zsh is the primary shell.
[[ $- == *i* ]] || return

source "$HOME/.config/shell/env.sh"
source "$XDG_CONFIG_HOME/shell/functions.sh"
for module in options tools; do
	source "$XDG_CONFIG_HOME/bash/$module.bash"
done
unset module
source "$XDG_CONFIG_HOME/shell/aliases.sh" # last, so aliases never rewrite config code
[[ -r $XDG_CONFIG_HOME/bash/local.bash ]] && source "$XDG_CONFIG_HOME/bash/local.bash"
