#!/usr/bin/env bash
# Switch the terminal setup of a live machine from the old dotfiles to this repo, reversibly.
#
# terminal: the old links and real files of every terminal entry (shells, kitty, foot, tmux,
#   nvim and its data, git, yazi, btop, lazygit, pgcli, music) move aside into the switch dir,
#   the repo is linked for exactly those entries, and the machine's own settings (local.zsh, git
#   identities, kitty font and keys, shell history) are copied in as untracked local files.
#   The desktop (WM, bar, launcher, .profile, fonts), ~/.claude and opencode stay as they are.
# rollback: puts back every link and file exactly as recorded, and removes what the switch added.
# status: shows whether the machine is switched.
#
# usage: switch.sh terminal [old-dotfiles-dir] | rollback | status
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=.local/lib/desktop/log.sh
source "$repo/.local/lib/desktop/log.sh"
dir="${XDG_STATE_HOME:-$HOME/.local/state}/rewrite-switch"
manifest="$dir/manifest"   # <kind>\t<path>[\t<link target>]: moved | link | created
backup="$dir/backup"
leftovers="$dir.leftovers" # what the new setup wrote where the old one comes back (kept)

# What the switch replaces (relative to $HOME). Old-only entries (.zshrc, .tmux.conf) go too:
# tmux would read ~/.tmux.conf before the new config.
entries=(
	.zshenv .zshrc .bashrc .vimrc .psqlrc .tmux.conf
	.config/bash .config/shell .config/zsh .config/kitty .config/foot .config/tmux .config/nvim
	.config/git .config/starship.toml .config/yazi .config/btop .config/fastfetch .config/lazygit
	.config/pgcli .config/rmpc .config/mpd .config/vm .config/systemd/user/mpd.service.d
	.config/systemd/user/mpd-mpris.service.d
	.local/bin/theme .local/bin/music .local/bin/vm .local/bin/mcp-sync .local/bin/desktop-doctor
	.local/lib/desktop .local/share/desktop
	.local/share/nvim .local/state/nvim .cache/nvim
)
git_local() { # <old git config>: its identity, credential helper and URL shortcuts, plus the
	# per-folder identities (the tracked config has none of these)
	local old=$1 key value tmp
	tmp=$(mktemp)
	if [[ -r $old ]]; then
		while read -r key value; do
			[[ $key == url.https://github.com/.insteadof ]] && continue # tracked (gh:)
			git config -f "$tmp" --add "$key" "$value"
		done < <(git config -f "$old" --get-regexp '^(user|credential|url)\.')
	fi
	# shellcheck disable=SC2088 # git expands ~ in these paths itself
	[[ -e $HOME/.config/git/personal.gitconfig ]] && git config -f "$tmp" 'includeIf.gitdir:~/Code/.path' '~/.config/git/personal.gitconfig'
	# shellcheck disable=SC2088
	[[ -e $HOME/.config/git/work.gitconfig ]] && git config -f "$tmp" 'includeIf.gitdir:~/Work/.path' '~/.config/git/work.gitconfig'
	echo '# Machine-only git settings (untracked), carried over from the old dotfiles'
	cat "$tmp"
	rm -f "$tmp"
}

record() { printf '%s\n' "$(IFS=$'\t'; echo "$*")" >>"$manifest"; }

link_entry() { # <path under $HOME>: link every repo file under it, as stow --no-folding would
	local entry=$1 src rel dest parent
	[[ -e $repo/$entry ]] || return 0
	while IFS= read -r src; do
		rel=${src#"$repo"/}
		dest="$HOME/$rel"
		parent=$(dirname "$dest")
		make_dir "$parent"
		ln -s "$(realpath -s --relative-to="$parent" "$src")" "$dest"
		record created "$rel"
	done < <(find "$repo/$entry" \( -type f -o -type l \) ! -path '*/__pycache__/*' | sort)
}

make_dir() { # <dir>: create it and its missing parents, recording each
	local d=$1 missing=()
	while [[ ! -d $d ]]; do missing=("$d" "${missing[@]}") && d=$(dirname "$d"); done
	for d in "${missing[@]}"; do mkdir "$d" && record dir "${d#"$HOME"/}"; done
}

terminal() {
	local old=${1:-$HOME/dot-files}
	[[ ! -e $manifest ]] || die already_switched msg="rollback first: $0 rollback"
	mkdir -p "$backup"
	: >"$manifest"
	# any failure from here on undoes what was done so far
	trap 'log_error switch_failed msg="rolling back"; rollback; exit 1' ERR

	# 1. Move the old setup aside
	local p
	for p in "${entries[@]}"; do
		if [[ -L $HOME/$p ]]; then
			record link "$p" "$(readlink "$HOME/$p")"
			rm "$HOME/$p"
		elif [[ -e $HOME/$p ]]; then
			mkdir -p "$(dirname "$backup/$p")"
			mv "$HOME/$p" "$backup/$p"
			record moved "$p"
		fi
	done

	# 2. The repo, for the terminal entries only
	for p in "${entries[@]}"; do link_entry "$p"; done

	# 3. This machine's own settings, as untracked local files (read from the old setup)
	local_file() { # <path under $HOME> <content source command...>
		local target="$HOME/$1"
		shift
		[[ -e $target ]] && return 0
		"$@" >"$target"
		record created "${target#"$HOME"/}"
	}
	[[ -r $old/.config/zsh/local.zsh ]] && local_file .config/zsh/local.zsh cat "$old/.config/zsh/local.zsh"
	local id
	for id in personal work; do
		[[ -r $old/.config/git/$id.gitconfig ]] && local_file ".config/git/$id.gitconfig" cat "$old/.config/git/$id.gitconfig"
	done
	local_file .config/git/local.gitconfig git_local "$old/.config/git/config"
	[[ -r $old/.config/kitty/kitty.conf ]] &&
		local_file .config/kitty/local.conf grep -E '^(font_family|map f8 )' "$old/.config/kitty/kitty.conf"
	# history moves to ~/.local/state/zsh; start it from the old one
	if [[ -r $HOME/.zsh_history && ! -e $HOME/.local/state/zsh/history ]]; then
		make_dir "$HOME/.local/state/zsh"
		local_file .local/state/zsh/history cat "$HOME/.zsh_history"
		record history "$(wc -l <"$HOME/.zsh_history")"
	fi

	# 4. Theme and shell plugins (no signals: running apps keep what they have)
	local state="${XDG_STATE_HOME:-$HOME/.local/state}/desktop/theme"
	if [[ ! -e $state ]]; then
		make_dir "$(dirname "$state")"
		python3 "$repo/.local/lib/desktop/theme_render.py" render tokyonight dark
		record created "${state#"$HOME"/}"
	fi
	"$repo/packages/plugins.sh" >/dev/null
	record created .config/zsh/plugins
	record created .config/tmux/plugins

	trap - ERR
	log_info switched part=terminal manifest="$manifest"
	echo "New terminals use the rewrite; open ones keep the old setup until closed (tmux: until its server restarts)."
	echo "Undo: $0 rollback"
}

rollback() {
	[[ -e $manifest ]] || die not_switched
	trap - ERR
	set +e # restore everything possible, then report what couldn't be
	local kind p target failed=0 copied
	# 0. Commands typed while switched go back into the old history
	copied=$(awk -F'\t' '$1 == "history" { print $2 }' "$manifest")
	if [[ -n $copied && -r $HOME/.local/state/zsh/history ]]; then
		tail -n +"$((copied + 1))" "$HOME/.local/state/zsh/history" >>"$HOME/.zsh_history" || failed=1
	fi
	# 1. Remove what the switch added, newest first: links, local files, plugins, theme, then dirs
	while IFS=$'\t' read -r kind p target; do
		case $kind in
		created) rm -rf -- "${HOME:?}/$p" || failed=1 ;;
		dir) rmdir -- "$HOME/$p" 2>/dev/null || { log_warn not_empty path="$p" && failed=1; } ;;
		esac
	done < <(tac "$manifest")
	# 2. Put the old setup back exactly as recorded; anything the new setup created in its place
	#    (nvim data, caches) is kept in the leftovers dir, never deleted
	while IFS=$'\t' read -r kind p target; do
		[[ $kind == link || $kind == moved ]] || continue
		if [[ -e $HOME/$p || -L $HOME/$p ]]; then
			if ! { mkdir -p "$(dirname "$leftovers/$p")" && mv "$HOME/$p" "$leftovers/$p"; }; then
				failed=1
				continue
			fi
		fi
		mkdir -p "$(dirname "$HOME/$p")" || failed=1
		case $kind in
		link) ln -s "$target" "$HOME/$p" || failed=1 ;;
		moved) mv "$backup/$p" "$HOME/$p" || failed=1 ;;
		esac
	done <"$manifest"
	if ((failed)); then
		log_error rollback_incomplete msg="see warnings above; the record stays in $dir"
		return 1
	fi
	rm -rf -- "$dir"
	log_info rolled_back part=terminal
	[[ ! -e $leftovers ]] || echo "Files the new setup created where the old ones were are kept in $leftovers"
}

status() {
	if [[ -e $manifest ]]; then
		echo "switched: terminal ($(grep -c . "$manifest") recorded changes, undo: $0 rollback)"
	else
		echo 'not switched'
	fi
}

case ${1:-} in
terminal) shift && terminal "$@" ;;
rollback) rollback ;;
status) status ;;
*) sed -n '13s/^# //p' "${BASH_SOURCE[0]}" >&2 && exit 2 ;;
esac
