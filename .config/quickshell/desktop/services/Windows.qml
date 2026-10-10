pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The open windows, most recently focused first (the switcher's ring), and the switcher's state.
// The list is reread from i3's tree (sway's on Wayland) whenever a window changes; the order comes
// from focus events. While switching, i3 is in mode "switcher", which sends its keys back over IPC
// (keys.conf): Alt+Tab steps on. Letting go of Alt switches: i3 can't see that (Alt was pressed
// before its mode began), so desktop-key-release waits for it.
Singleton {
	id: root

	property var mru: [] // container ids, most recent first
	property var windows: [] // { id, title, cls, workspace, focused }
	property bool switching: false
	property bool shown: false // the ring shows once Alt is held a moment (a quick tap just switches)
	property int selected: 0

	function step(by: int): void {
		const n = windows.length;
		if (n === 0) {
			close(); // nothing to switch to: leave the window manager's switcher mode
			return;
		}
		if (!switching) {
			switching = true;
			selected = (by > 0 ? Math.min(1, n - 1) : n - 1);
			showLater.restart();
			ctrl.running = !Quickshell.env("WAYLAND_DISPLAY");
			return;
		}
		selected = (selected + by + n) % n;
		shown = true;
	}

	function choose(index: int): void {
		selected = index;
		commit();
	}

	// the ring goes first, then the focus: as it goes, the window manager focuses whatever is under
	// the pointer (focus follows the mouse), so the chosen window is focused after that
	function commit(): void {
		const target = windows[selected];
		close();
		if (target) {
			focusLater.target = target.id;
			focusLater.restart();
		}
	}

	function close(): void {
		showLater.stop();
		ctrl.running = false;
		switching = false;
		shown = false;
		WindowManager.command('mode "default"');
	}

	function read(tree: var): void {
		const found = [];
		const walk = (node, workspace) => {
			if (node.type === "workspace")
				workspace = node.name;
			if (workspace === "__i3_scratch")
				return;
			const cls = node.window_properties?.class ?? node.app_id ?? "";
			const name = node.name ?? "";
			// the shell's own windows (named quickshell, or "Desktop …") aren't switched to
			if ((node.window || node.app_id !== undefined && node.pid) && !/quickshell/i.test(cls) && name !== "quickshell" && !name.startsWith("Desktop "))
				found.push({ id: node.id, title: name, cls, instance: node.window_properties?.instance ?? cls, workspace, focused: node.focused });
			for (const child of [...(node.nodes ?? []), ...(node.floating_nodes ?? [])])
				walk(child, workspace);
		};
		walk(tree, "");
		const rank = w => {
			const i = mru.indexOf(w.id);
			return w.focused ? -1 : i < 0 ? 1e6 : i;
		};
		windows = found.sort((a, b) => rank(a) - rank(b));
		if (switching)
			selected = Math.min(selected, Math.max(0, windows.length - 1));
	}

	Timer {
		id: focusLater

		property var target

		interval: 260 // the ring unmaps after 220 ms
		onTriggered: WindowManager.command(`[con_id=${target}] focus`)
	}

	Timer {
		id: showLater

		interval: 140
		onTriggered: if (root.switching) root.shown = true
	}

	// Alt let go (or not held at all: a quick tap): switch
	Process {
		id: ctrl

		command: ["desktop-key-release", "alt"]
		onExited: code => {
			if (code === 0 && root.switching)
				root.commit();
			else if (root.switching)
				root.close();
		}
	}

	Connections {
		target: WindowManager

		function onWindowEvent(data: var): void {
			const id = data.container?.id;
			if (data.change === "focus" && id !== undefined && !(data.container.name ?? "").startsWith("Desktop ")) {
				root.mru = [id, ...root.mru.filter(m => m !== id)].slice(0, 100);
				root.windows = root.windows.map(w => w.focused === (w.id === id) ? w : Object.assign({}, w, { focused: w.id === id }));
			}
			else if (data.change === "close")
				root.mru = root.mru.filter(m => m !== id);
			else if (data.change === "title" && root.windows.some(w => w.id === id))
				root.windows = root.windows.map(w => w.id === id ? Object.assign({}, w, { title: data.container.name ?? "" }) : w);
		}

		// the window list, from the tree WindowManager reads after each change (no second read)
		function onTreeRead(tree: var): void {
			root.read(tree);
		}
	}
}
