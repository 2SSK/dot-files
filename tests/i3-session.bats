#!/usr/bin/env bats
# The minimal i3 session's own commands: desktop i3 (what the keys ask of the shell), menu (rofi:
# a fake answering what each test lines up, see rofi.bash), bar's modules, record, level and
# cliphist. The tools they drive are fakes recording what they were asked.

setup() {
	load rofi
	LIB="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin"
	export CALLS="$BATS_TEST_TMPDIR/calls" HOME="$BATS_TEST_TMPDIR/home"
	export XDG_CONFIG_HOME="$HOME/.config" XDG_STATE_HOME="$HOME/.local/state" XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin" "$XDG_CONFIG_HOME/desktop" "$XDG_RUNTIME_DIR"
	fake_rofi "$bin"
	for tool in i3-msg loginctl systemctl notify-send dunstctl polybar-msg brightnessctl-set; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	# desktop: records; answers what the menus ask of it
	cat >"$bin/desktop" <<'EOF'
#!/usr/bin/env bash
echo "desktop $*" >>"$CALLS"
case "$1 ${2:-}" in
"record running") exit "${RECORDING:-1}" ;;
"font current") echo geist ;;
"font list") printf '  inter  Inter + JetBrains Mono\n* geist  Geist + Geist Mono\n' ;;
"clipboard copy") cat >>"$CALLS" && echo >>"$CALLS" ;;
"clipboard watch") printf '%s\n' '{"kind":"text","text":"one"}' '{"kind":"text","text":"two"}' '{"kind":"text","text":"one"}' ;;
"capture record")
	trap 'mkdir -p "$(dirname "$4")" && echo saved >"$4"; exit 0' INT
	echo recording
	while :; do sleep 0.05; done
	;;
esac
EOF
	printf '#!/bin/sh\necho "theme $*" >>"$CALLS"\n[ "$1" = list ] && printf "  catppuccin\\n* tokyonight\\n"\nexit 0\n' >"$bin/theme"
	printf '#!/bin/sh\necho "wpctl $*" >>"$CALLS"\n[ "$1" = get-volume ] && echo "Volume: 0.40${MUTED:+ [MUTED]}"\nexit 0\n' >"$bin/wpctl"
	printf '#!/bin/sh\necho "brightnessctl $*" >>"$CALLS"\n[ "$1" = -m ] && echo "intel_backlight,backlight,48000,50%%,96000"\nexit 0\n' >"$bin/brightnessctl"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
	unset DISPLAY WAYLAND_DISPLAY
}

@test "desktop i3: every \$shell call in keys.conf has an answer" {
	local call
	while read -r call; do
		# shellcheck disable=SC2086 # the words of the call
		run "$LIB/i3" $call
		[ "$status" -eq 0 ] || { echo "no answer for: $call" && false; }
	done < <(grep -ohE '\$shell [a-z]+ [a-z]+( [a-z0-9]+)?' "$BATS_TEST_DIRNAME"/../.config/i3/conf.d/*.conf | sed 's/^\$shell //' | sort -u)
	run "$LIB/i3" frobnicate now
	[ "$status" -eq 2 ]
}

@test "desktop i3: each key reaches its menu; the switcher and power keys leave their i3 mode" {
	"$LIB/i3" launcher toggle emoji
	"$LIB/i3" audio up
	"$LIB/i3" brightness down
	"$LIB/i3" settings page keys
	"$LIB/i3" switcher next
	"$LIB/i3" power open
	[ "$(grep -v '^i3-msg' "$CALLS")" = "$(printf '%s\n' 'desktop menu emoji' 'desktop level volume up' 'desktop level brightness down' \
		'desktop menu keys' 'desktop menu windows' 'desktop menu power')" ]
	[ "$(grep -c '^i3-msg -q mode default' "$CALLS")" -eq 2 ]
}

@test "menu power: a number picks it; reboot asks for a second press, anything else keeps the session" {
	answer 10 "" # 1: lock
	"$LIB/menu" power
	grep -qx "loginctl lock-session" "$CALLS"
	: >"$CALLS" && : >"$BATS_TEST_TMPDIR/rofi-count" && : >"$ROFI_ANSWERS"
	answer 13 "" # 4: reboot, the first press
	answer 1 ""  # Esc
	"$LIB/menu" power
	! grep -q "^systemctl" "$CALLS"
	grep -q "^rofi .*-mesg <span foreground='[^']*'>Reboot? press 4 or Enter again</span>" "$CALLS" # it asks
	grep -q "^rofi .*-selected-row 3 " "$CALLS"    # and stays picked
	: >"$CALLS" && : >"$BATS_TEST_TMPDIR/rofi-count" && : >"$ROFI_ANSWERS"
	answer 13 "" # 4 once
	answer 10 "" # then 1: lock instead, at once
	"$LIB/menu" power
	grep -qx "loginctl lock-session" "$CALLS" && ! grep -q "^systemctl" "$CALLS"
	: >"$CALLS" && : >"$BATS_TEST_TMPDIR/rofi-count" && : >"$ROFI_ANSWERS"
	answer 0 "4" # Shut down, by Enter
	answer 0 "4" # Enter again
	"$LIB/menu" power
	grep -qx "systemctl poweroff" "$CALLS"
	[ "$(rows 1 | wc -l)" -eq 5 ] && ! rows 1 | sed 's/<[^>]*>//g' | grep -q '[A-Za-z]' # five icons, no names
}

@test "menu power: without confirm in the settings, reboot goes at once" {
	echo '{"power":{"confirm":false}}' >"$XDG_CONFIG_HOME/desktop/shell.json"
	answer 13 ""
	"$LIB/menu" power
	grep -qx "systemctl reboot" "$CALLS"
}

@test "menu capture: letters take a shot or record; while recording the row stops it" {
	answer 15 "" # Shift+s: record the screen
	"$LIB/menu" capture
	grep -qx "desktop record start screen" "$CALLS"
	: >"$CALLS" && : >"$BATS_TEST_TMPDIR/rofi-count" && : >"$ROFI_ANSWERS"
	answer 0 "3" # the fourth row while recording: Stop recording
	RECORDING=0 "$LIB/menu" capture
	grep -qx "desktop record stop" "$CALLS"
	rows 1 | grep -q "Stop recording"
	[ "$(rows 1 | wc -l)" -eq 6 ]
}

@test "menu theme: Enter applies a family, Alt+m flips dark and light" {
	answer 0 "0"
	"$LIB/menu" theme
	grep -qx "theme set catppuccin" "$CALLS"
	answer 10 ""
	"$LIB/menu" theme
	grep -qx "theme mode toggle" "$CALLS"
}

@test "menu font: the collections by name, the current one marked" {
	answer 0 "0"
	"$LIB/menu" font
	grep -qx "desktop font set inter" "$CALLS"
	grep -q "^rofi .*-a 1 -selected-row 1" "$CALLS"
	[ "$(rows 1)" = "$(printf 'Inter + JetBrains Mono\nGeist + Geist Mono')" ]
}

@test "menu notifications: the history newest first; Alt+c clears it, Alt+n toggles do-not-disturb" {
	cat >"$bin/dunstctl" <<'EOF'
#!/bin/sh
echo "dunstctl $*" >>"$CALLS"
case $1 in
history) echo '{"type":"aa{sv}","data":[[{"id":{"data":7},"summary":{"data":"Saved <a>"},"body":{"data":"file\nhere"},"appname":{"data":"App"},"timestamp":{"data":1}}]]}' ;;
is-paused) echo false ;;
esac
EOF
	chmod +x "$bin/dunstctl"
	printf '#!/bin/sh\nexit 0\n' >"$bin/pgrep" && chmod +x "$bin/pgrep"
	answer 11 "0"
	"$LIB/menu" notifications
	grep -qx "dunstctl history-clear" "$CALLS"
	[[ $(rows 1) == "<b>Saved &lt;a&gt;</b>  <span alpha='60%'>App · "*"</span>"$'\n'"<span alpha='70%' size='small'>file here</span>" ]]
	answer 0 "0"
	"$LIB/menu" notifications
	grep -qx "dunstctl history-pop 7" "$CALLS"
}

@test "menu keys: Enter runs the binding, a \$shell one through desktop i3" {
	mkdir -p "$XDG_CONFIG_HOME/i3/conf.d"
	printf 'bindsym $mod+d $shell launcher toggle apps\nbindsym $mod+Return exec $term\nmode "x" {\n\tbindsym Escape mode "default"\n}\n' \
		>"$XDG_CONFIG_HOME/i3/conf.d/keys.conf"
	answer 0 "0"
	"$LIB/menu" keys
	grep -qx "i3-msg -q exec --no-startup-id desktop i3 launcher toggle apps" "$CALLS"
	[ "$(rows 1 | wc -l)" -eq 2 ]
	rows 1 | grep -q "^Super+d *launcher toggle apps$"
}

@test "bar battery: bat and the level, chr while charging, nothing without a battery" {
	export DESKTOP_POWER_SUPPLY="$BATS_TEST_TMPDIR/ps"
	mkdir -p "$XDG_STATE_HOME/desktop/theme"
	echo '{"ui":{"fg_muted":"#999999","primary":"#0000ff","success":"#00ff00","error":"#ff0000"}}' >"$XDG_STATE_HOME/desktop/theme/palette.json"
	run "$LIB/bar" battery
	[ "$output" = "" ]
	mkdir -p "$DESKTOP_POWER_SUPPLY/BAT1" && echo 64 >"$DESKTOP_POWER_SUPPLY/BAT1/capacity" && echo Discharging >"$DESKTOP_POWER_SUPPLY/BAT1/status"
	run "$LIB/bar" battery
	[ "$output" = "%{F#0000ff}bat%{F-} 64%" ]
	echo Charging >"$DESKTOP_POWER_SUPPLY/BAT1/status"
	run "$LIB/bar" battery
	[ "$output" = "%{F#0000ff}chr%{F-} %{F#00ff00}64%%{F-}" ]
	echo 12 >"$DESKTOP_POWER_SUPPLY/BAT1/capacity" && echo Discharging >"$DESKTOP_POWER_SUPPLY/BAT1/status"
	run "$LIB/bar" battery
	[ "$output" = "%{F#0000ff}bat%{F-} %{F#ff0000}12%%{F-}" ]
}

@test "record: starts once the region is picked, stops on stop, announces the file" {
	"$LIB/record" start region
	for _ in $(seq 60); do
		"$LIB/record" running && break
		sleep 0.05
	done
	"$LIB/record" running
	grep -q "^desktop capture record region $HOME/Videos/Recordings/Recording .*\.mp4$" "$CALLS"
	run "$LIB/record" start screen
	[ "$status" -eq 1 ]
	"$LIB/record" stop
	for _ in $(seq 60); do
		grep -q "^notify-send" "$CALLS" && break
		sleep 0.05
	done
	grep -q "^notify-send -a Screen recording .*Recording saved" "$CALLS"
	! "$LIB/record" running
}

@test "level: volume up unmutes and caps at 100 %, shown as one replacing card" {
	"$LIB/level" volume up
	grep -qx "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0" "$CALLS"
	grep -qx "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+" "$CALLS"
	grep -q "^notify-send -a Level -i audio-volume-high -t 1400 -h int:value:40 -h string:x-dunst-stack-tag:level .* Volume 40%$" "$CALLS"
	MUTED=1 "$LIB/level" mic mute
	grep -q "Microphone off$" "$CALLS"
	"$LIB/level" brightness down
	grep -qx "brightnessctl -q -n1 set 5%-" "$CALLS"
	grep -q "Brightness 50%$" "$CALLS"
	run "$LIB/level" volume sideways
	[ "$status" -eq 2 ]
}

@test "cliphist: keeps each copy once, newest first; the menu copies one back" {
	"$LIB/cliphist" keep
	run "$LIB/cliphist" list
	[ "${#lines[@]}" -eq 2 ]
	[[ ${lines[0]} == *'"text": "one"'* && ${lines[1]} == *'"text": "two"'* ]]
	[ -f "$XDG_RUNTIME_DIR/desktop/clipboard/history.json" ] # persist off: in RAM
	answer 0 "1"
	"$LIB/cliphist" menu
	grep -qx "desktop clipboard copy text" "$CALLS" && grep -qx "two" "$CALLS"
}

@test "cliphist: with persist on, the shell's own history file, and its limit" {
	echo '{"clipboard":{"persist":true,"max":1}}' >"$XDG_CONFIG_HOME/desktop/shell.json"
	"$LIB/cliphist" keep
	[ "$(jq '.entries | length' "$XDG_STATE_HOME/desktop/clipboard/history.json")" -eq 1 ]
	answer 12 "" # Alt+c: clear
	"$LIB/cliphist" menu
	[ "$(jq '.entries | length' "$XDG_STATE_HOME/desktop/clipboard/history.json")" -eq 0 ]
}

@test "no menu binds a key rofi already uses (rofi would show an error and hold the keyboard)" {
	local real
	real="$(PATH="${PATH#*:}" command -v rofi)" || skip 'rofi not installed'
	printf '#!/bin/sh\nexit 1\n' >"$bin/dunstctl" && chmod +x "$bin/dunstctl"
	local m
	for m in apps windows emoji theme font capture power keys settings notifications; do
		timeout 10 "$LIB/menu" "$m" >/dev/null 2>&1 || true
	done
	timeout 10 "$LIB/cliphist" menu >/dev/null 2>&1 || true
	XDG_DATA_HOME="$BATS_TEST_TMPDIR/data" timeout 10 "$LIB/todo" >/dev/null 2>&1 || true
	XDG_DATA_HOME="$BATS_TEST_TMPDIR/data" timeout 10 "$LIB/notes" >/dev/null 2>&1 || true
	[ "$(grep -c '^rofi' "$CALLS")" -ge 12 ]
	# each call's -kb-* options, then rofi's own table with them: no key twice
	run python3 - "$real" "$CALLS" <<'PY'
import re, subprocess, sys
bad = []
for line in open(sys.argv[2]):
    if not line.startswith("rofi "):
        continue
    kb = [x for t in re.findall(r"-kb-[\w-]+ \S*", line) for x in t.split(" ", 1)]
    table = subprocess.run([sys.argv[1], *kb, "-list-keybindings"], capture_output=True, text=True).stdout
    seen = {}
    for row in table.splitlines():
        m = re.match(r"\s*(kb-[\w-]+) - (.*)", row)
        for key in (k.strip() for k in (m[2].split(",") if m else []) if k.strip()):
            if key in seen and seen[key] != m[1]:
                bad.append(f"{key}: {seen[key]} and {m[1]} in {line[:60]}")
            seen[key] = m[1]
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
	[ "$status" -eq 0 ] || { echo "$output" && false; }
}
