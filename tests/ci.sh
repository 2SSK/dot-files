#!/usr/bin/env bash
# What CI runs, in a clean Arch container (the same here: docker run --rm -v "$PWD:/repo" -w /repo
# archlinux:latest tests/ci.sh): lint every shell script, then the tests. Nothing needs a display.
set -euo pipefail

if [[ ${CI_SETUP:-1} == 1 ]] && command -v pacman >/dev/null; then
	pacman -Syu --noconfirm --needed bash bats jq python python-pytest git stow \
		zsh tmux fzf fd ripgrep imagemagick which diffutils procps-ng xz sudo >/dev/null
	# the static ShellCheck build: Arch's package pulls in a hundred Haskell libraries
	curl -fsSL https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz |
		tar -xJ -C /usr/local/bin --strip-components=1 shellcheck-v0.10.0/shellcheck
fi

# the tests run as a normal user, as on the laptop (some check permissions)
if ((EUID == 0)); then
	id tester >/dev/null 2>&1 || useradd -m -s /usr/bin/zsh tester # zsh: as setup.sh leaves it
	chown -R tester "$PWD"
	exec su tester -c "CI_SETUP=0 HOME=/home/tester $0"
fi

git config --global --add safe.directory "$PWD"
# as after setup.sh: the repo's commands on PATH (they call each other by name)
export PATH="$PWD/.local/bin:$PATH"

echo "== shellcheck"
git ls-files -z | while IFS= read -r -d '' f; do
	[[ $f == .claude/* ]] && continue # vendored skills
	if head -c 40 "$f" 2>/dev/null | grep -qE '^#!.*\b(bash|sh)\b'; then printf '%s\0' "$f"; fi
done | xargs -0 shellcheck -x -S warning

echo "== theme renderer"
python3 -m pytest -q tests/test_theme_render.py

echo "== bats"
bats --jobs 1 tests/*.bats
