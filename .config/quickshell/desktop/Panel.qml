pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3

// What the island shows beyond the bar: nothing, the OSD (a level that just changed) or the power
// menu. While the power menu is open i3 is in mode "power", which sends its keys back over IPC
// (keys.conf): an X11 popup can't take the keyboard itself.
Singleton {
	id: root

	property bool barShown: true
	property string view: "" // "", "osd" or "power"
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
		if (view === "power")
			return;
		osdKind = kind;
		osdValue = value;
		osdMuted = muted;
		view = "osd";
		osdTimer.restart();
	}

	function toggleBar(): void {
		barShown = !barShown;
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
		onTriggered: if (root.view === "osd") root.view = ""
	}

	Timer {
		id: armTimer

		interval: 3000
		onTriggered: root.armed = -1
	}
}
