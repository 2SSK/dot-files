# shellcheck shell=bash
# shellcheck disable=SC1091 # runtime path
cached_init dircolors.bash dircolors -b
source "$XDG_CONFIG_HOME/shell/fzf.sh"
if [[ ${BLE_VERSION-} ]]; then
	ble-import -d integration/fzf-completion
	ble-import -d integration/fzf-key-bindings
else
	cached_init fzf.bash fzf --bash
fi
cached_init zoxide.bash zoxide init bash --cmd cd
cached_init starship.bash starship init bash
