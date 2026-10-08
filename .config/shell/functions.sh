# shellcheck shell=bash
# Functions shared by bash and zsh.

# cached_init <cache-name> <cmd...>: source the output of an init command (starship init,
# zoxide init, ...), regenerated only when the binary is newer than the cache.
cached_init() {
	local cache="$XDG_CACHE_HOME/shell/$1" bin
	bin="$(command -v "$2")" || return 0
	if [[ ! $cache -nt $bin ]]; then
		mkdir -p "${cache%/*}"
		"${@:2}" >"$cache"
	fi
	# shellcheck disable=SC1090 # generated file
	source "$cache"
}

# yazi that leaves the shell in the directory you were browsing when you quit
y() {
	local tmp cwd
	tmp="$(mktemp -t yazi-cwd.XXXXXX)"
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd <"$tmp"
	if [[ -n $cwd && $cwd != "$PWD" ]]; then cd -- "$cwd" || :; fi # cd reports its own error
	rm -f -- "$tmp"
}

# Fuzzy-pick processes to kill
fkill() {
	local pids
	pids="$(ps -u "$USER" -o pid=,comm=,args= | fzf -m --prompt='kill> ' | awk '{print $1}')"
	[[ -n $pids ]] && echo "$pids" | xargs kill -"${1:-TERM}"
}

# Fuzzy ripgrep: frg <pattern>, opens the match in $EDITOR at its line
frg() {
	local hit
	hit="$(rg --line-number --no-heading --smart-case --color=always "${1:?usage: frg <pattern>}" |
		fzf --ansi --delimiter=: --prompt='rg> ' \
			--preview 'bat --color=always --highlight-line {2} {1}' --preview-window='+{2}-/2')"
	[[ -n $hit ]] && "$EDITOR" +"$(cut -d: -f2 <<<"$hit")" "$(cut -d: -f1 <<<"$hit")"
}

# Browse git log; enter shows the commit
# shellcheck disable=SC2016 # expanded by fzf, not here
fgl() {
	git log --oneline --graph --color=always "$@" |
		fzf --ansi --no-sort --reverse --prompt='log> ' \
			--preview 'git show --color=always $(grep -o "[a-f0-9]\{7,\}" <<<{} | head -1)' \
			--bind 'enter:execute(git show --color=always $(grep -o "[a-f0-9]\{7,\}" <<<{} | head -1) | less -R)'
}

# Fuzzy docker exec into a running container
fdex() {
	local id
	id="$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' | fzf --prompt='exec> ' | cut -f1)"
	[[ -n $id ]] && docker exec -it "$id" "${1:-sh}"
}

# claude and opencode, and the MCP servers they start, get the keys in ~/.config/secrets.env;
# nothing else run from the shell sees them
with_secrets() {
	(
		local env="$XDG_CONFIG_HOME/secrets.env"
		set -a
		# shellcheck disable=SC1090 # untracked, per machine
		[[ -r $env ]] && source "$env"
		set +a
		"$@"
	)
}
claude() { with_secrets command claude "$@"; }
opencode() { with_secrets command opencode "$@"; }

# Servers rarely have the terminfo of kitty, foot or st ("unknown terminal type", broken clear and
# keys), so ssh from those connects as xterm-256color; the local terminal keeps its own TERM
ssh() {
	case $TERM in
	xterm-kitty | foot | foot-extra | st-256color) TERM=xterm-256color command ssh "$@" ;;
	*) command ssh "$@" ;;
	esac
}
