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

# Like zsh: Ctrl+e accepts the suggestion (ble default), Alt+l accepts the next word, Ctrl+w
# accepts and runs it; Ctrl+p/n search history by prefix (Ctrl+h/j/k/l belong to tmux)
ble-bind -m auto_complete -f C-w auto_complete/accept-line
ble-bind -m auto_complete -f M-l 'auto_complete/@end insert-cword'
ble-bind -m vi_imap -f C-p history-search-backward
ble-bind -m vi_imap -f C-n history-search-forward
