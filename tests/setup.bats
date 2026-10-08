#!/usr/bin/env bats
# setup.sh -y --no-packages against a throwaway $HOME.

setup() {
	REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export HOME="$BATS_TEST_TMPDIR/home"
	unset XDG_STATE_HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME
	mkdir -p "$HOME"
	mkdir -p "$BATS_TEST_TMPDIR/bin" # fake pkill/xrdb/tmux: never touch the developer's terminals
	for tool in pkill xrdb tmux gsettings i3-msg; do printf '#!/bin/sh\n' >"$BATS_TEST_TMPDIR/bin/$tool" && chmod +x "$BATS_TEST_TMPDIR/bin/$tool"; done
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "links tracked files and skips ignored ones" {
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ "$(readlink -f "$HOME/.config/i3/config")" = "$REPO/.config/i3/config" ]
	[ ! -e "$HOME/README.md" ]
	[ ! -e "$HOME/packages" ]
}

@test "moves a conflicting real file to the backup dir" {
	mkdir -p "$HOME/.config/i3"
	echo mine >"$HOME/.config/i3/config"
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ -L "$HOME/.config/i3/config" ]
	run cat "$HOME"/.local/state/desktop/backup/*/.config/i3/config
	[ "$output" = mine ]
}

@test "removes stale links into the repo, keeps foreign links" {
	ln -s "$REPO/README.md" "$HOME/README.md"
	ln -s "$REPO/gone.conf" "$HOME/gone.conf"
	ln -s /etc/hostname "$HOME/foreign"
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ ! -L "$HOME/README.md" ]
	[ ! -L "$HOME/gone.conf" ]
	[ -L "$HOME/foreign" ]
}

@test "second run is a no-op" {
	"$REPO/setup.sh" -y --no-packages
	before="$(find "$HOME" -printf '%p %l\n' | sort)"
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ "$(find "$HOME" -printf '%p %l\n' | sort)" = "$before" ]
}

@test "unknown option is a usage error" {
	run "$REPO/setup.sh" --bogus
	[ "$status" -eq 2 ]
}

@test "refuses to prompt without a terminal unless -y" {
	run "$REPO/setup.sh" --no-packages </dev/null
	[ "$status" -eq 2 ]
	[ ! -e "$HOME/.config" ]
}

@test "--wm rejects unknown values" {
	run "$REPO/setup.sh" --wm kde
	[ "$status" -eq 2 ]
}

@test "a foreign link as the last symlink found doesn't abort setup" {
	ln -s /etc/hostname "$HOME/only-foreign"
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ -L "$HOME/.config/i3/config" ]
}

@test "renders the default theme, then keeps the current one" {
	run "$REPO/setup.sh" -y --no-packages
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/.local/state/desktop/theme/current")" = "$(printf 'family=tokyonight\nmode=dark')" ]
	python3 "$REPO/.local/lib/desktop/theme_render.py" render gruvbox light
	"$REPO/setup.sh" -y --no-packages
	grep -q '^family=gruvbox$' "$HOME/.local/state/desktop/theme/current"
	grep -q '^initial-color-theme=light$' "$HOME/.local/state/desktop/theme/foot.ini"
}
