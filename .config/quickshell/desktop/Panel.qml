pragma Singleton

import QtQuick
import Quickshell

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
	property string settingsPage: "bar"
	property bool controlOpen: false
	property bool clipboardOpen: false
	property bool clipboardShown: false // lives on while it slides back into the bar
	property bool authOpen: false // the password prompt (polkit), while an app asks
	property bool captureOpen: false
	property bool captureShown: false
	property string captureAsk: "" // "shot" or "record": the panel only asks which screen
	readonly property int captureWidth: 520
	readonly property int captureHeight: 324
	property bool launcherOpen: false
	property bool launcherShown: false
	property string launcherMode: "apps" // apps, emoji, files or themes
	readonly property int launcherWidth: 640
	readonly property int launcherHeight: 560
	property bool wallpaperOpen: false
	property bool wallpaperShown: false
	readonly property int wallpaperWidth: 720
	readonly property int wallpaperHeight: 540
	// the open panel hanging from the bar (its width; 0 for none): the bar opens its outline there
	readonly property int hangingWidth: controlOpen ? controlWidth : clipboardOpen ? 560 : wallpaperOpen ? wallpaperWidth : launcherOpen ? launcherWidth : captureOpen ? captureWidth : authOpen ? 480 : 0
	readonly property int hangingHeight: controlOpen ? controlHeight : clipboardOpen ? 560 : wallpaperOpen ? wallpaperHeight : launcherOpen ? launcherHeight : captureOpen ? captureHeight : authOpen ? 250 : 0

	// the capture panel; ask: "shot" or "record" to go straight to choosing a screen
	function openCapture(ask: string): void {
		captureAsk = ask === "shot" || ask === "record" ? ask : "";
		captureOpen = true;
	}

	// the password prompt takes the place of any other panel
	onAuthOpenChanged: if (authOpen) {
		controlOpen = false;
		clipboardOpen = false;
		wallpaperOpen = false;
		launcherOpen = false;
		captureOpen = false;
	}

	onCaptureOpenChanged: {
		if (captureOpen) {
			controlOpen = false;
			clipboardOpen = false;
			wallpaperOpen = false;
			launcherOpen = false;
			showCapture.restart();
		} else {
			hideCapture.restart();
		}
	}

	Timer {
		id: showCapture

		interval: 0
		onTriggered: root.captureShown = root.captureOpen
	}

	Timer {
		id: hideCapture

		interval: 0
		onTriggered: if (!root.captureOpen) root.captureShown = false
	}

	// the launcher on a mode; again on the same mode closes it
	function toggleLauncher(mode: string): void {
		if (launcherOpen && launcherMode === mode) {
			launcherOpen = false;
			return;
		}
		launcherMode = mode || "apps";
		launcherOpen = true;
	}

	onLauncherOpenChanged: {
		if (launcherOpen) {
			controlOpen = false;
			captureOpen = false;
			clipboardOpen = false;
			wallpaperOpen = false;
			showLauncher.restart();
		} else {
			hideLauncher.restart();
		}
	}

	Timer {
		id: showLauncher

		interval: 0
		onTriggered: root.launcherShown = root.launcherOpen
	}

	Timer {
		id: hideLauncher

		interval: 0
		onTriggered: if (!root.launcherOpen) root.launcherShown = false
	}

	onWallpaperOpenChanged: {
		if (wallpaperOpen) {
			controlOpen = false;
			captureOpen = false;
			clipboardOpen = false;
			launcherOpen = false;
			showWallpaper.restart();
		} else {
			hideWallpaper.restart();
		}
	}

	Timer {
		id: showWallpaper

		interval: 0
		onTriggered: root.wallpaperShown = root.wallpaperOpen
	}

	Timer {
		id: hideWallpaper

		interval: 0
		onTriggered: if (!root.wallpaperOpen) root.wallpaperShown = false
	}

	onClipboardOpenChanged: {
		if (clipboardOpen) {
			controlOpen = false;
			wallpaperOpen = false;
			captureOpen = false;
			launcherOpen = false;
			showClipboard.restart();
		} else {
			hideClipboard.restart();
		}
	}

	Timer {
		id: showClipboard

		interval: 0
		onTriggered: root.clipboardShown = root.clipboardOpen
	}

	Timer {
		id: hideClipboard

		interval: 0
		onTriggered: if (!root.clipboardOpen) root.clipboardShown = false
	}
	property var islands: ({}) // screen name -> the bar's rect on it (screen coordinates from its origin)
	property string controlPage: "home"

	// the control center's panel, centred under the bar, and the inverse curves joining it to the bar
	readonly property int controlWidth: 760
	readonly property int controlHeight: 640
	readonly property int controlFillet: 18

	// the control center's window lives on while it slides back into the bar
	property bool controlShown: false

	onControlOpenChanged: {
		if (controlOpen) {
			clipboardOpen = false;
			captureOpen = false;
			wallpaperOpen = false;
			launcherOpen = false;
			showControl.restart();
		} else {
			hideControl.restart();
		}
	}

	Timer {
		id: showControl

		interval: 0
		onTriggered: root.controlShown = root.controlOpen
	}

	Timer {
		id: hideControl

		interval: 0
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
		{ id: "lock", glyph: Icons.g("lock"), label: "Lock", confirm: false },
		{ id: "logout", glyph: Icons.g("logout"), label: "Log Out", confirm: true },
		{ id: "suspend", glyph: Icons.g("zzz"), label: "Lock & Suspend", confirm: false },
		{ id: "reboot", glyph: Icons.g("refresh"), label: "Reboot", confirm: true },
		{ id: "poweroff", glyph: Icons.g("power"), label: "Shut Down", confirm: true }
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
		Quickshell.execDetached([Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg", "-q", 'mode "power"']);
	}

	function closePower(): void {
		if (view === "power")
			view = "";
		armed = -1;
		Quickshell.execDetached([Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg", "-q", 'mode "default"']);
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
