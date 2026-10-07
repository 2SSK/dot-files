# Interactive zsh. Order matters: vi keymap before plugins (bindkey -v resets keymaps),
# fzf-tab before the widget-wrapping plugins, tools last, aliases after all of it.
source "$XDG_CONFIG_HOME/shell/functions.sh"

for module in options completion keys plugins tools; do
	source "$ZDOTDIR/$module.zsh"
done
unset module
source "$XDG_CONFIG_HOME/shell/aliases.sh" # last, so aliases never rewrite config code

[[ -r $ZDOTDIR/local.zsh ]] && source "$ZDOTDIR/local.zsh"
