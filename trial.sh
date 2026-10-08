#!/usr/bin/env bash
# Try the rewrite's terminal setup next to the live one, without changing the live one.
#
# A separate home in ~/.local/share/rewrite-trial gets the repo stowed into it plus links to
# everything real (projects, ~/.ssh, tool configs, fonts, ~/.claude) that the rewrite doesn't
# provide. A kitty window runs there with HOME pointing at it, inside a capped systemd scope, with
# its own tmux server, nvim plugins, history and theme. Nothing outside the trial home is written.
#
# usage: trial.sh start [family] [mode]   build (or refresh) the trial home and open a window
#        trial.sh clean                   close every trial window and delete the trial home
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
real="$HOME"
trial="$real/.local/share/rewrite-trial"
scope=rewrite-trial

# Real home entries the trial must not see: the old shell configs (they would win over the
# rewrite's) and per-app state the trial keeps for itself
skip_home='^(\.cache|\.config|\.local|\.zshrc.*|\.zshenv|\.zsh_history|\.zcompdump.*|\.bashrc|\.bash_profile|\.bash_history.*|\.profile|\.vimrc|\.viminfo|\.tmux\.conf|\.tmux|\.psqlrc|\.psql_history|\.wezterm\.lua|\.oh-my-zsh|\.zsh)$'
share_whitelist=(fonts icons themes applications keyrings)

link_missing() { # <real dir> <trial dir> [skip regex]: link entries the trial doesn't have
	local src=$1 dst=$2 skip=${3:-'^$'} entry name
	mkdir -p "$dst"
	for entry in "$src"/* "$src"/.[!.]*; do
		[[ -e $entry || -L $entry ]] || continue
		name=${entry##*/}
		[[ $name =~ $skip || -e $dst/$name || -L $dst/$name ]] && continue
		ln -s "$entry" "$dst/$name"
	done
}

start() {
	local family=${1:-tokyonight} mode=${2:-dark}
	command -v stow kitty >/dev/null || { echo 'trial: needs stow and kitty' >&2 && exit 1; }
	mkdir -p "$trial"

	# The rewrite itself (its .claude stays out: the trial uses the live Claude Code)
	stow -d "$repo" -t "$trial" --no-folding --restow --ignore='\.claude' .

	# Everything real that work needs
	link_missing "$real" "$trial" "$skip_home"
	link_missing "$real/.config" "$trial/.config"
	local d
	for d in "${share_whitelist[@]}"; do
		[[ -e $real/.local/share/$d && ! -e $trial/.local/share/$d ]] && ln -s "$real/.local/share/$d" "$trial/.local/share/$d"
	done

	# Laptop-only settings, as untracked local files (the live originals are only read)
	[[ -e $trial/.config/zsh/local.zsh || ! -e $real/.config/zsh/local.zsh ]] ||
		cp "$real/.config/zsh/local.zsh" "$trial/.config/zsh/local.zsh"
	if [[ ! -e $trial/.config/git/local.gitconfig ]]; then
		cat >"$trial/.config/git/local.gitconfig" <<-EOF
			# Identity per folder, as on the live setup (real paths: the trial home links to them)
			[includeIf "gitdir:$real/Code/"]
			  path = $real/.config/git/personal.gitconfig
			[includeIf "gitdir:$real/Work/"]
			  path = $real/.config/git/work.gitconfig
		EOF
	fi
	if [[ ! -e $trial/.config/kitty/local.conf ]]; then
		grep -sE '^(font_family|map f8 )' "$real/.config/kitty/kitty.conf" >"$trial/.config/kitty/local.conf" || true
	fi

	# Theme and shell plugins, inside the trial home only (no signals to live apps)
	local in_trial=(env -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_STATE_HOME -u XDG_CACHE_HOME HOME="$trial")
	"${in_trial[@]}" python3 "$repo/.local/lib/desktop/theme_render.py" render "$family" "$mode"
	"${in_trial[@]}" "$repo/packages/plugins.sh" >/dev/null

	# The window: capped, a clean environment (live exports like STARSHIP_CONFIG or FZF_* would mix
	# the old setup in), its own tmux socket dir, and the live ~/.local/bin still on PATH
	local keep=(DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS SSH_AUTH_SOCK SWAYSOCK I3SOCK
		XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP LANG LC_ALL USER LOGNAME SHELL)
	local vars=() v
	for v in "${keep[@]}"; do [[ -n ${!v:-} ]] && vars+=("$v=${!v}"); done
	mkdir -p "$trial/.run"
	systemd-run --user --scope --unit="$scope-$(date +%s)" --slice="$scope.slice" \
		-p MemoryMax=4G -p CPUQuota=300% --quiet \
		env -i "${vars[@]}" HOME="$trial" TMUX_TMPDIR="$trial/.run" \
		PATH="$real/.local/bin:/usr/local/bin:/usr/bin:/bin" XAUTHORITY="${XAUTHORITY:-$real/.Xauthority}" \
		kitty --class rewrite-trial --title 'rewrite trial' --directory "$real" >/dev/null 2>&1 &
	disown
	echo "trial: window opened (HOME=$trial); close it, or run: trial.sh clean"
}

clean() {
	systemctl --user stop "$scope.slice" 2>/dev/null || true # every trial window and what runs in it
	[[ -d $trial ]] || { echo 'trial: nothing to clean' && return; }
	# links first, so nothing they point to can be touched, then the trial's own files
	find "$trial" -type l -delete
	rm -rf -- "$trial"
	echo "trial: removed $trial"
}

case ${1:-} in
start) shift && start "$@" ;;
clean) clean ;;
*) sed -n '9,10s/^# //p' "${BASH_SOURCE[0]}" >&2 && exit 2 ;;
esac
