#!/usr/bin/env bats
# desktop-timeshift: Timeshift's snapshots as JSON for the settings page; making and deleting them
# through pkexec. Fakes: timeshift prints a list like the real one; sudo and pkexec run or refuse.

setup() {
	TS="$BATS_TEST_DIRNAME/../.local/bin/desktop-timeshift"
	export CALLS="$BATS_TEST_TMPDIR/calls"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	cat >"$bin/timeshift" <<'FAKE'
#!/bin/sh
echo "timeshift $*" >>"$CALLS"
case $* in
*--list*)
	cat <<'LIST'
Mounted '/dev/nvme0n1p2' at '/run/timeshift/1234/backup'
Device : /dev/nvme0n1p2
UUID   : e408de8b-954e-4fb8-95a9-355e2df4cb8c
Path   : /run/timeshift/1234/backup
Mode   : BTRFS
Status : OK
2 snapshots, 183.2 GB free

Num     Name                 Tags  Description
------------------------------------------------------------------------------
0    >  2026-10-08_10-00-01  D
1    >  2026-10-09_18-30-12  O     before the shell switch
LIST
	;;
esac
FAKE
	# sudo: refuses without a password unless $SUDO_OK; pkexec: runs it
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "sudo $*" >>"$CALLS"\n[ "$1" = -n ] && shift\n[ -n "$SUDO_OK" ] || exit 1\n"$@"\n' >"$bin/sudo"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "pkexec $*" >>"$CALLS"\n"$@"\n' >"$bin/pkexec"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

@test "list: the snapshots, newest first, with tags, comments and the device" {
	SUDO_OK=1 run "$TS" list
	[ "$status" -eq 0 ]
	python3 -c '
import json, sys
d = json.loads(sys.argv[1])
assert d["mode"] == "BTRFS" and d["status"] == "OK" and d["free"] == "183.2 GB free", d
s = d["snapshots"]
assert [x["name"] for x in s] == ["2026-10-09_18-30-12", "2026-10-08_10-00-01"], s
assert s[0]["tags"] == "O" and s[0]["comment"] == "before the shell switch", s[0]
assert s[1]["tags"] == "D" and s[1]["comment"] == "", s[1]
' "$output"
	grep -qx "timeshift --list --scripted" "$CALLS"
}

@test "list without the passwordless rule says so, unless asked to ask" {
	run "$TS" list
	[ "$status" -eq 3 ]
	run "$TS" list --ask
	[ "$status" -eq 0 ]
	grep -q "^pkexec timeshift --list --scripted" "$CALLS"
}

@test "create and delete go through pkexec" {
	"$TS" create "before an upgrade"
	"$TS" delete 2026-10-08_10-00-01
	grep -qx "pkexec timeshift --create --comments before an upgrade --scripted" "$CALLS"
	grep -qx "pkexec timeshift --delete --snapshot 2026-10-08_10-00-01 --scripted" "$CALLS"
}

@test "a snapshot name that isn't one is refused" {
	run "$TS" delete "../../etc"
	[ "$status" -eq 2 ]
	! grep -q "^pkexec" "$CALLS" 2>/dev/null
}
