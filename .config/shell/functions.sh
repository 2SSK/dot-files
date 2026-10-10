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

# s: search the repos and the AUR, preview each package, install the ones picked (Tab marks several)
s() {
	yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S
}

mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# extract <archive>: unpacks into the current directory, picking the tool by extension
extract() {
	[[ -f $1 ]] || { echo "not a file: $1" >&2 && return 1; }
	case $1 in
	*.tar.* | *.tar | *.tgz | *.tbz2) tar xf "$1" ;;
	*.zip) unzip "$1" ;;
	*.rar) unrar x "$1" ;;
	*.7z) 7z x "$1" ;;
	*.gz) gunzip -k "$1" ;;
	*.bz2) bunzip2 -k "$1" ;;
	*.xz) unxz -k "$1" ;;
	*.zst) unzstd "$1" ;;
	*) echo "don't know how to extract: $1" >&2 && return 1 ;;
	esac
}

# killport <port>: stop whatever listens on a TCP port
killport() {
	[[ -n $1 ]] || { echo 'usage: killport <port>' >&2 && return 2; }
	fuser -k -TERM "$1/tcp" || echo "nothing on port $1"
}

# myip: the address on the local network, and the one the internet sees
myip() {
	ip -4 route get 1.1.1.1 | awk '{ for (i = 1; i < NF; i++) if ($i == "src") print "Local:    " $(i + 1) }'
	printf 'External: %s\n' "$(curl -fsS --max-time 5 ifconfig.me)"
}

# share [-t 1h|12h|24h|72h] <file|folder>... : upload to catbox.moe, print the links and copy them.
# A folder goes as a .tar.gz, piped text (`git diff | share`) as paste.txt. -t: litterbox instead,
# which deletes it after that time (and takes up to 1 GB instead of 200 MB).
share() {
	local api="https://catbox.moe/user/api.php" max=200 expiry="" tmp f name url urls="" nl=$'\n'
	local -a opts=(-fS -F reqtype=fileupload)
	if [[ ${1:-} == -t ]]; then
		[[ ${2:-} =~ ^(1|12|24|72)h$ ]] || { echo "share: -t takes 1h, 12h, 24h or 72h" >&2 && return 2; }
		api="https://litterbox.catbox.moe/resources/internals/api.php" max=1024 expiry=$2
		opts+=(-F "time=$expiry")
		shift 2
	fi
	if (($# == 0)) && [[ -t 0 ]]; then
		echo "usage: share [-t 1h|12h|24h|72h] <file|folder>...   or: <command> | share" >&2
		return 2
	fi
	if [[ -t 2 ]]; then opts+=(--progress-bar); else opts+=(-s); fi
	tmp="$(mktemp -d)" || return
	if (($# == 0)); then
		cat >"$tmp/paste.txt"
		set -- "$tmp/paste.txt"
	fi
	for f in "$@"; do
		if [[ -d $f ]]; then # a folder: packed first
			f="$(realpath -- "$f")" name="$(basename -- "$f")"
			tar -C "$(dirname -- "$f")" -czf "$tmp/$name.tar.gz" -- "$name" || continue
			f="$tmp/$name.tar.gz"
		elif [[ ! -f $f ]]; then
			echo "share: no such file: $f" >&2
			continue
		fi
		if (($(stat -c %s -- "$f") > max * 1024 * 1024)); then
			echo "share: $f is over $max MB${expiry:+ even for litterbox}" >&2
			[[ -n $expiry ]] || echo "  share -t 72h takes up to 1 GB" >&2
			continue
		fi
		url="$(curl "${opts[@]}" -F "fileToUpload=@\"$f\"" "$api")"
		if [[ $url != https://* ]]; then # catbox answers errors as text
			echo "share: $f failed${url:+: $url}" >&2
			continue
		fi
		printf '%s\n' "$url"
		urls+="${urls:+$nl}$url" # (zsh keeps $'\n' literal inside quotes)
	done
	rm -rf -- "$tmp"
	[[ -n $urls ]] || return 1
	if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
		printf '%s' "$urls" | wl-copy
	else
		printf '%s' "$urls" | xclip -selection clipboard
	fi && echo "copied${expiry:+ (deleted after $expiry)}" >&2
}
