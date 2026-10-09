pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3

// Shell state: whether the bar is shown (or peeking while hidden), the OSD card (a level or lock
// that just changed) and the power menu. While the power menu is open i3 is in mode "power", which sends its keys back over IPC
// (keys.conf): an X11 popup can't take the keyboard itself.
Singleton {
	id: root

	property bool barShown: true
	property bool peek: false // the hidden bar showing while the pointer is at the edge
	property string view: "" // "" or "power"
	property bool osdShown: false
	property bool settingsOpen: false
	property bool controlOpen: false
	property var islands: ({}) // screen name -> the bar's rect on it (screen coordinates from its origin)
	property rect controlRect // where the control center sits, from its screen's origin
	property string controlPage: "home"

	// The control center appears a moment after its click catcher (Dismiss), so i3 stacks it above
	// the catcher: clicks on it reach it, clicks elsewhere close it.
	property bool controlShown: false

	// closing slides it back into the bar first
	onControlOpenChanged: controlOpen ? showControl.restart() : hideControl.restart()

	Timer {
		id: showControl

		interval: 60
		onTriggered: root.controlShown = root.controlOpen
	}

	Timer {
		id: hideControl

		interval: 230
		onTriggered: if (!root.controlOpen) root.controlShown = false
	}

	// the control center, on a page (home, notifications, ...); again on the same page closes it
	function toggleControl(page: string): void {
		if (controlOpen && controlPage === page) {
			controlOpen = false;
			return;
		}
		controlPage = page;
		controlOpen = true;
	}
	property string osdKind: "volume" // volume, mic, brightness, caps or num
	property real osdValue: 0
	property bool osdMuted: false
	property int selected: 0
	property int armed: -1 // the action waiting for its confirming press

	// Lock keeps the laptop running (closing the lid only locks too); nothing hibernates. Actions
	// that end the session ask for a second press while power.confirm is on.
	readonly property var actions: [
		{ id: "lock", glyph: "\u{F0341}", label: "Lock", confirm: false },
		{ id: "logout", glyph: "\u{F0343}", label: "Log Out", confirm: true },
		{ id: "suspend", glyph: "\u{F03E4}", label: "Lock & Suspend", confirm: false },
		{ id: "reboot", glyph: "\u{F0709}", label: "Reboot", confirm: true },
		{ id: "poweroff", glyph: "\u{F0425}", label: "Shut Down", confirm: true }
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
		if (Config.power.confirm && actions[index].confirm && armed !== index) {
			armed = index;
			armTimer.restart();
			return;
		}
		closePower();
		pending = actions[index].id;
		run.restart(); // once the menu has faded, so the lock screen's blur doesn't catch it
	}

	property string pending: ""

	Timer {
		id: run

		interval: 280
		onTriggered: root.execute(root.pending)
	}

	function execute(id: string): void {
		// the locker (desktop-lock, run by xss-lock on X11) locks for lock-session and before sleep
		Quickshell.execDetached({
			lock: ["loginctl", "lock-session"],
			logout: Quickshell.env("SWAYSOCK") ? ["swaymsg", "exit"] : ["i3-msg", "exit"],
			suspend: ["systemctl", "suspend"],
			reboot: ["systemctl", "reboot"],
			poweroff: ["systemctl", "poweroff"]
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
