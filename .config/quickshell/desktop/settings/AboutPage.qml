pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.control
import qs.widgets

// Settings → About: this machine and this desktop, read once as the page opens. A click on a line
// copies it; Copy all copies them all (for a bug report).
Column {
	id: page

	spacing: 22

	property var facts: [] // [{ section, label, value }]

	function copy(text: string): void {
		Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | desktop clipboard copy text', "sh", text]);
	}

	// one "section<TAB>label<TAB>value" line per fact; a missing tool leaves its line out
	Process {
		running: true
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
			onStreamFinished: page.facts = text.split("\n").filter(l => l).map(l => {
				const [section, label, value] = l.split("\t");
				return { section, label, value };
			})
		}
	}

	Repeater {
		model: ["System", "Desktop"]

		delegate: Section {
			id: group

			required property string modelData

			title: modelData

			Repeater {
				model: page.facts.filter(f => f.section === group.modelData)

				delegate: SettingRow {
					id: fact

					required property var modelData

					label: modelData.label
					hint: modelData.value

					Glyph {
						glyph: Icons.g("copy")
						color: factHover.hovered ? Theme.fg : Qt.alpha(Theme.fgMuted, 0.6)
						font.pixelSize: 14
					}

					HoverHandler {
						id: factHover

						parent: fact
					}

					MouseArea {
						parent: fact
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: page.copy(fact.modelData.value)
					}
				}
			}
		}
	}

	SmallButton {
		visible: page.facts.length > 0
		text: "Copy all"
		onClicked: page.copy(page.facts.map(f => `${f.label}: ${f.value}`).join("\n"))
	}
}
