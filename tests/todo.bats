#!/usr/bin/env bats
# desktop todo: to-dos in ~/.local/share/desktop/todo.md, from a terminal and in rofi (a fake that
# answers what each test lines up: see rofi.bash).

setup() {
	load rofi
	TODO="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/todo"
	export CALLS="$BATS_TEST_TMPDIR/calls" HOME="$BATS_TEST_TMPDIR/home"
	export XDG_DATA_HOME="$HOME/.local/share" XDG_STATE_HOME="$HOME/.local/state"
	FILE="$XDG_DATA_HOME/desktop/todo.md"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin" "$XDG_DATA_HOME/desktop"
	fake_rofi "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "notify-send $*" >>"$CALLS"\n' >"$bin/notify-send"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

@test "add: a task with its day, and ! for high priority" {
	"$TODO" add "Pay rent @2030-01-04"
	"$TODO" add "! Call the bank"
	grep -qx -- "- \[ \] Pay rent \*(added: $(date +%F), due: 2030-01-04)\*" "$FILE"
	grep -qx -- "- \[ \] Call the bank \*(added: $(date +%F), priority: high)\*" "$FILE"
}

@test "a due time said in words keeps the time; a day alone stays a day" {
	"$TODO" add "Standup @tomorrow 9:30"
	"$TODO" add "Groceries @tomorrow"
	grep -q "Standup \*(added: .*, due: $(date -d tomorrow +%F) 09:30)\*" "$FILE"
	grep -q "Groceries \*(added: .*, due: $(date -d tomorrow +%F))\*" "$FILE"
}

@test "list: open tasks, high first, then the soonest due; done marks one" {
	"$TODO" add "Later @2031-01-01"
	"$TODO" add "Sooner @2030-01-01"
	"$TODO" add "! Urgent"
	run "$TODO" list
	[[ ${lines[0]} == *"Urgent" && ${lines[1]} == *"Sooner"* && ${lines[2]} == *"Later"* ]]
	"$TODO" done 2
	grep -qx -- "- \[x\] ~~Sooner~~ \*(added: .*, due: 2030-01-01, done: $(date +%F))\*" "$FILE"
	run "$TODO" list
	[ "${#lines[@]}" -eq 2 ]
}

@test "lines written by hand stay, and the file reads back as written" {
	printf '# To-do\n\n- [ ] Plain one\n- [x] ~~Old~~ *(done: 2026-01-01)*\nsome words of mine\n' >"$FILE"
	"$TODO" add "New"
	grep -qx -- "- \[ \] Plain one" "$FILE"
	grep -qx -- "- \[x\] ~~Old~~ \*(done: 2026-01-01)\*" "$FILE"
	grep -qx "some words of mine" "$FILE"
}

@test "migrate: the shell's todo.json moves in once, its priorities kept" {
	printf '%s' '{"items":[{"text":"Low one","priority":"low","done":false,"rank":1},{"text":"High one","priority":"high","done":false,"rank":0},{"text":"Done one","priority":"medium","done":true,"rank":2}]}' \
		>"$XDG_DATA_HOME/desktop/todo.json"
	"$TODO" migrate
	[ -f "$XDG_DATA_HOME/desktop/todo.json.bak" ] && [ ! -e "$XDG_DATA_HOME/desktop/todo.json" ]
	[ "$(grep -c '^- \[' "$FILE")" -eq 3 ]
	grep -q "High one .*priority: high" "$FILE"
	grep -q "Low one .*priority: low" "$FILE"
	grep -q '^- \[x\] ~~Done one~~' "$FILE"
}

@test "menu: typing a new task and Enter adds it, Alt+x marks done, Alt+d deletes" {
	"$TODO" add "First"
	"$TODO" add "Second"
	answer 0 "-1 Third @2030-02-02" # typed, matching no task
	answer 10 "1 "                  # Alt+x on row 1, First (Third leads: a due date comes first)
	answer 11 "0 "                  # Alt+d on row 0, Third
	run "$TODO"
	[ "$status" -eq 0 ]
	grep -q '^- \[x\] ~~First~~' "$FILE"
	! grep -q "Third" "$FILE"
	grep -q '^- \[ \] Second' "$FILE"
	rows 1 | grep -qx "First"
	[ "$(rows 2 | head -1)" = "Third   <span foreground='#a6adc8' size='small'>Sat 02 Feb 2030</span>" ]
	[[ $(sed -n 1p "$CALLS") == *"-p todo · 2"* ]]
}

@test "menu: a task's actions set its due date, a reminder and its priority" {
	"$TODO" add "Task"
	answer 0 "0 "            # Enter on Task: its actions
	answer 0 "1 "            # Set due date
	answer 0 "-1 2030-03-03" # typed
	answer 0 "0 "            # Task again
	answer 0 "2 "            # Set reminder
	answer 0 "-1 2030-03-01" # a day: the reminder comes at 09:00
	answer 0 "0 "
	answer 0 "4 " # Priority: medium → high
	run "$TODO"
	grep -qx -- "- \[ \] Task \*(added: .*, due: 2030-03-03, remind: 2030-03-01 09:00, priority: high)\*" "$FILE"
}

@test "menu: a task's text in markup is shown as text" {
	"$TODO" add "a <b> & c"
	run "$TODO"
	rows 1 | grep -qxF "a &lt;b&gt; &amp; c"
}

@test "check: a reminder or due time that has come is told once" {
	printf -- '- [ ] Past *(remind: 2020-01-01 10:00)*\n- [ ] Future *(remind: 2099-01-01 10:00)*\n- [x] ~~Done~~ *(remind: 2020-01-01 10:00)*\n' >"$FILE"
	"$TODO" check
	"$TODO" check
	[ "$(grep -c '^notify-send' "$CALLS")" -eq 1 ]
	grep -q "Reminder: Past" "$CALLS"
}

@test "the menu leaves the shell's todo.json alone (sway's to-do page keeps using it)" {
	echo '{"items":[{"text":"Shell task"}]}' >"$XDG_DATA_HOME/desktop/todo.json"
	run "$TODO"
	[ -f "$XDG_DATA_HOME/desktop/todo.json" ] && [ ! -e "$XDG_DATA_HOME/desktop/todo.json.bak" ]
}
