pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// This machine and this desktop, for Settings → About: read once a few seconds after the shell starts
// (lspci, sway, qs and git take a moment), then again in the background each time the page opens, so
// it shows at once with what's known and updates in place.
Singleton {
	id: root

	property var facts: [] // [{ section, label, value }]

	function refresh(): void {
		if (!reader.running)
			reader.running = true;
	}

	Timer {
		running: true
		interval: 4000 // after the shell has settled
		onTriggered: root.refresh()
	}

	// one "section<TAB>label<TAB>value" line per fact; a missing tool leaves its line out
	Process {
		id: reader

		command: ["sh", "-c", `
			. /etc/os-release 2>/dev/null
			line() { [ -n "$3" ] && printf '%s\\t%s\\t%s\\n' "$1" "$2" "$3"; }
			dmi=/sys/devices/virtual/dmi/id
			line System "Device" "$(cat $dmi/sys_vendor 2>/dev/null) $(cat $dmi/product_name 2>/dev/null)"
			line System "Operating system" "$PRETTY_NAME"
			line System "Kernel" "$(uname -r)"
			line System "Processor" "$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1) · $(grep -c ^processor /proc/cpuinfo) threads"
			line System "Graphics" "$(lspci 2>/dev/null | sed -n 's/.*\\(VGA\\|3D\\)[^:]*: //p' | sed 's/Corporation //; s/ (rev [0-9a-f]*)//' | paste -sd, - | sed 's/,/, /g')"
			line System "Memory" "$(free -h --si | awk '/^Mem:/ { print $2 " (" $3 " in use)" }')"
			line System "Disk" "$(df -h --output=size,used,avail / | awk 'NR == 2 { print $2 " used of " $1 ", " $3 " free" }')"
			line System "Up" "$(uptime -p | sed 's/^up //')"
			line Desktop "Compositor" "$( [ -n "$WAYLAND_DISPLAY" ] && sway --version 2>/dev/null || i3 --version 2>/dev/null | cut -d' ' -f1-3)"
			line Desktop "Shell" "$(qs --version 2>/dev/null | head -1 | sed "s/ (revision.*//")"
			line Desktop "Theme" "$(theme current 2>/dev/null)"
			line Desktop "Dot-files" "$(git -C "$HOME/dot-files" log -1 --format='%h · %s (%cr)' 2>/dev/null)"
		`]
		stdout: StdioCollector {
			onStreamFinished: root.facts = text.split("\n").filter(l => l).map(l => {
				const [section, label, value] = l.split("\t");
				return { section, label, value };
			})
		}
	}
}
