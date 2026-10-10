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
	property string controlPage: "home"
	property bool clipboardOpen: false
	property bool authOpen: false // the password prompt (polkit), while an app asks
	property bool captureOpen: false
	property string captureAsk: "" // "shot" or "record": the panel only asks which screen
	property bool launcherOpen: false
	property string launcherMode: "apps" // apps, emoji, files or themes
	property bool wallpaperOpen: false
	property var islands: ({}) // screen name -> the bar's rect on it (screen coordinates from its origin)

	// The panels hanging from the bar: one open at a time. Each one's window (a Loader in shell.qml)
	// follows *Shown, which trails *Open by an event-loop turn, so the panel being replaced is gone
	// before the next one takes the keyboard.
	readonly property var panels: ["control", "clipboard", "capture", "launcher", "wallpaper"]
	property bool controlShown: false
	property bool clipboardShown: false
	property bool captureShown: false
	property bool launcherShown: false
	property bool wallpaperShown: false

	// each panel's size, centred under the bar (the bar opens its outline there: hangingWidth)
	readonly property int controlWidth: 760
	readonly property int controlHeight: 640
	readonly property int controlFillet: 18
	readonly property int clipboardWidth: 920
	readonly property int clipboardHeight: 580
	readonly property int captureWidth: 520
	readonly property int captureHeight: 324
	readonly property int launcherWidth: 640
	readonly property int launcherHeight: 560
	readonly property int wallpaperWidth: 720
	readonly property int wallpaperHeight: 540
	readonly property var sizes: ({
			control: [controlWidth, controlHeight],
			clipboard: [clipboardWidth, clipboardHeight],
			wallpaper: [wallpaperWidth, wallpaperHeight],
			launcher: [launcherWidth, launcherHeight],
			capture: [captureWidth, captureHeight],
			auth: [480, 250]
		})
	readonly property string hanging: authOpen ? "auth" : panels.find(p => root[p + "Open"]) ?? ""
	readonly property int hangingWidth: sizes[hanging]?.[0] ?? 0
	readonly property int hangingHeight: sizes[hanging]?.[1] ?? 0

	// a panel opened closes the others (the password prompt closes them all)
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

	// the capture panel; ask: "shot" or "record" to go straight to choosing a screen
	function openCapture(ask: string): void {
		captureAsk = ask === "shot" || ask === "record" ? ask : "";
		captureOpen = true;
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
