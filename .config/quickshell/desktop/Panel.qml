pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Shell state: the bar, the OSD card, the hanging panels and the power menu. While the power menu is
// open i3 is in mode "power" and sends its keys back over IPC, since an X11 popup can't take the keyboard.
Singleton {
	id: root

	property bool barShown: true
	property bool peek: false // the hidden bar showing while the pointer is at the edge
	property string view: "" // "" or "power"
	property bool osdShown: false
	property bool settingsOpen: false
	property string settingsPage: "bar"
	property bool controlOpen: false
	property string controlPage: "home"
	property bool clipboardOpen: false
	property bool authOpen: false // the polkit password prompt
	property bool captureOpen: false
	property string captureAsk: "" // "shot" or "record": the panel only asks which screen
	property bool launcherOpen: false
	property string launcherMode: "apps" // apps, emoji, files or themes
	property bool wallpaperOpen: false
	property var islands: ({}) // screen name -> the bar's rect on it (screen coordinates from its origin)

	// One panel open at a time. Each window follows *Shown, which trails *Open by an event-loop turn,
	// so the panel being replaced is gone before the next one takes the keyboard.
	readonly property var panels: ["control", "clipboard", "capture", "launcher", "wallpaper"]
	property bool controlShown: false
	property bool clipboardShown: false
	property bool captureShown: false
	property bool launcherShown: false
	property bool wallpaperShown: false

	// each panel's size, centred under the bar, which opens its outline there (hangingWidth)
	readonly property var sizes: ({
			control: Qt.size(760, 700), // the home page with two players and 115% text
			clipboard: Qt.size(920, 580),
			wallpaper: Qt.size(720, 540),
			launcher: Qt.size(640, 560),
			capture: Qt.size(520, 324),
			auth: Qt.size(480, 250)
		})
	readonly property int fillet: 18
	readonly property string hanging: authOpen ? "auth" : panels.find(p => root[p + "Open"]) ?? ""
	readonly property int hangingWidth: sizes[hanging]?.width ?? 0
	property string hangingScreen: "" // the screen a panel hangs on (pinned as it opens: HangingPanel)

	function opened(name: string): void {
		if (name === "auth" ? authOpen : root[name + "Open"])
			panels.forEach(p => {
				if (p !== name)
					root[p + "Open"] = false;
			});
		settle.restart();
	}

	onControlOpenChanged: opened("control")
	onClipboardOpenChanged: opened("clipboard")
	onCaptureOpenChanged: opened("capture")
	onLauncherOpenChanged: opened("launcher")
	onWallpaperOpenChanged: opened("wallpaper")
	onAuthOpenChanged: opened("auth")

	Timer {
		id: settle

		interval: 0
		onTriggered: root.panels.forEach(p => root[p + "Shown"] = root[p + "Open"])
	}

	// ask is "shot" or "record" to go straight to choosing a screen
	function openCapture(ask: string): void {
		captureAsk = ask === "shot" || ask === "record" ? ask : "";
		captureOpen = true;
	}

	function toggleLauncher(mode: string): void {
		if (launcherOpen && launcherMode === mode) {
			launcherOpen = false;
			return;
		}
		launcherMode = mode || "apps";
		launcherOpen = true;
	}

	function showing(page: string): bool {
		return controlOpen && controlPage === page;
	}

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
		WindowManager.command('mode "power"');
	}

	function closePower(): void {
		if (view === "power")
			view = "";
		armed = -1;
		WindowManager.command('mode "default"');
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
			logout: [WindowManager.msg, "exit"],
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
