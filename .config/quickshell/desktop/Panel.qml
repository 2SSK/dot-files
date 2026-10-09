pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3

// Shell state: whether the bar is shown (or peeking while hidden), the OSD card (a level or lock
// that just changed) and the power menu the island grows into. While the power menu is open i3 is in mode "power", which sends its keys back over IPC
// (keys.conf): an X11 popup can't take the keyboard itself.
Singleton {
	id: root

	property bool barShown: true
	property bool peek: false // the hidden bar showing while the pointer is at the edge
	property string view: "" // "" or "power"
	property bool osdShown: false
	property string osdKind: "volume" // volume, mic, brightness, caps or num
	property real osdValue: 0
	property bool osdMuted: false
	property int selected: 0
	property int armed: -1 // the action waiting for its confirming press

	readonly property var actions: [
		{ id: "suspend", glyph: "󰒲", label: "Suspend" },
		{ id: "logout", glyph: "󰍃", label: "Log out" },
		{ id: "reboot", glyph: "󰜉", label: "Reboot" },
		{ id: "poweroff", glyph: "󰐥", label: "Shut down" },
		{ id: "firmware", glyph: "󰍛", label: "Firmware" }
	]

	function osd(kind: string, value: real, muted: bool): void {
		osdKind = kind;
		osdValue = value;
		osdMuted = muted;
		osdShown = true;
		osdTimer.restart();
	}

	function toggleBar(): void {
		barShown = !barShown;
		peek = false;
	}

	function openPower(): void {
		selected = 0;
		armed = -1;
		view = "power";
		I3.dispatch('mode "power"');
	}

	function closePower(): void {
		if (view === "power")
			view = "";
		armed = -1;
		I3.dispatch('mode "default"');
	}

	function togglePower(): void {
		view === "power" ? closePower() : openPower();
	}

	function move(step: int): void {
		selected = (selected + step + actions.length) % actions.length;
		armed = -1;
	}

	function activate(index: int): void {
		if (index < 0 || index >= actions.length)
			return;
		selected = index;
		if (Config.power.confirm && armed !== index) {
			armed = index;
			armTimer.restart();
			return;
		}
		const id = actions[index].id;
		closePower();
		Quickshell.execDetached({
			suspend: ["systemctl", "suspend"],
			logout: Quickshell.env("SWAYSOCK") ? ["swaymsg", "exit"] : ["i3-msg", "exit"],
			reboot: ["systemctl", "reboot"],
			poweroff: ["systemctl", "poweroff"],
			firmware: ["systemctl", "reboot", "--firmware-setup"]
		}[id]);
	}

	Timer {
		id: osdTimer

		interval: Config.osd.timeout
		onTriggered: root.osdShown = false
	}

	Timer {
		id: armTimer

		interval: 3000
		onTriggered: root.armed = -1
	}
}
