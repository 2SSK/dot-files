#!/usr/bin/env bats
# packages/cleanup.sh with fake pacman/docker/sudo/systemctl/yay/paccache recording what they were
# asked to do. Installed: jq (a dependency, listed by the repo), rofi and steam (in remove.txt).

setup() {
	CLEANUP="$BATS_TEST_DIRNAME/../packages/cleanup.sh"
	export CALLS="$BATS_TEST_TMPDIR/calls"
	bin="$BATS_TEST_TMPDIR/bin"
	mkdir -p "$bin"
	printf '#!/bin/sh\n"$@"\n' >"$bin/sudo"
	# shellcheck disable=SC2016 # expands when the fake runs
	cat >"$bin/pacman" <<'FAKE'
#!/bin/sh
case "$1" in
-Qq) case "$2" in jq | rofi | steam | cmatrix) exit 0 ;; *) exit 1 ;; esac ;;
-Qdtq) echo old-lib ;;
*) echo "pacman $*" >>"$CALLS" ;;
esac
FAKE
	for tool in systemctl docker yay paccache; do
		# shellcheck disable=SC2016
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

@test "packages: what the repo lists is kept, what remove.txt names goes, then orphans" {
	run "$CLEANUP" packages
	[ "$status" -eq 0 ]
	grep -qx "pacman -D --asexplicit jq" "$CALLS"
	grep -qx "pacman -Rns rofi steam" "$CALLS" # only what is installed
	grep -qx "pacman -Rns old-lib" "$CALLS"
	grep -qx "yay -S cmatrix-git" "$CALLS"
}

@test "packages: auto-cpufreq is stopped before its package goes" {
	run "$CLEANUP" packages
	[ "$status" -eq 0 ]
	[ "$(head -1 "$CALLS")" = "pacman -D --asexplicit jq" ]
	grep -qx "systemctl disable --now auto-cpufreq.service" "$CALLS"
}

@test "docker: named volumes stay" {
	run "$CLEANUP" docker
	[ "$status" -eq 0 ]
	grep -qx "docker volume prune -f" "$CALLS"
	! grep -q "volume prune.*-a" "$CALLS"
	grep -qx "docker image prune -a -f" "$CALLS"
}

@test "caches: keeps 2 versions of installed packages, none of removed ones" {
	run "$CLEANUP" caches
	[ "$status" -eq 0 ]
	grep -qx "paccache -r -k 2" "$CALLS"
	grep -qx "paccache -r -u -k 0" "$CALLS"
}

@test "unknown part is a usage error" {
	run "$CLEANUP" everything
	[ "$status" -eq 2 ]
}
