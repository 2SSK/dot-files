# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091 # sources runtime paths under $XDG_CONFIG_HOME
# Interactive bash with ble.sh (vim mode, autosuggestions, syntax highlighting).
# ble.sh loads first and attaches last, as its docs require.
[[ $- == *i* ]] || return

source "$HOME/.config/shell/env.sh"
_blesh="$XDG_DATA_HOME/blesh/ble.sh"
[[ -r $_blesh ]] && source -- "$_blesh" --attach=none --norc
unset _blesh

source "$XDG_CONFIG_HOME/shell/functions.sh"
for module in options keys tools; do
	source "$XDG_CONFIG_HOME/bash/$module.bash"
done
unset module
source "$XDG_CONFIG_HOME/shell/aliases.sh" # last, so aliases never rewrite config code
[[ -r $XDG_CONFIG_HOME/bash/local.bash ]] && source "$XDG_CONFIG_HOME/bash/local.bash"

[[ ! ${BLE_VERSION-} ]] || ble-attach
