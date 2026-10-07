setopt autocd interactive_comments no_nomatch notify numeric_glob_sort correct

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"
setopt extended_history share_history hist_ignore_all_dups hist_ignore_space \
	hist_reduce_blanks hist_save_no_dups hist_find_no_dups hist_verify
