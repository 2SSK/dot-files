# shellcheck shell=bash
# Vim mode; with ble.sh also jk, mode cursors and the zsh autosuggestion keys
set -o vi
[[ ${BLE_VERSION-} ]] || return 0

_ble_keys() {
	ble-bind -m vi_imap -f 'j k' vi_imap/normal-mode
	ble-bind -m vi_imap --cursor 5
	ble-bind -m vi_nmap --cursor 2
}
blehook/eval-after-load keymap_vi _ble_keys

# Ctrl+e accepts the suggestion (ble default); Ctrl+w accepts and runs it, like zsh
ble-bind -m auto_complete -f C-w auto_complete/accept-line
