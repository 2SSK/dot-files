pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the bar shows of i3 (or sway): the workspaces and the scratchpad. Read straight from the
// window manager, not through Quickshell.I3, whose event connections drop and then leave the bar
// stale: a long-lived `i3-msg -t subscribe -m` says when something changed (and is started again if
// i3 restarts or the connection goes), then the workspaces and the tree are reread.
Singleton {
	id: root

	readonly property string msg: Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg"
	property var workspaces: [] // { num, name, focused, visible, urgent, output }, by number
	property int scratchpad: 0 // windows that belong to the scratchpad
	property int scratchpadShown: 0 // of those, the ones out on a workspace now

	function switchTo(num: int): void {
		Quickshell.execDetached([msg, "-q", `workspace number ${num}`]);
	}

	function showScratchpad(): void {
		Quickshell.execDetached([msg, "-q", "scratchpad show"]);
	}

	// one line per event; several often come at once (a move fires a few): reread once they settle
	Process {
		id: events

		running: true
		command: [root.msg, "-t", "subscribe", "-m", '["workspace","window","output","mode"]']
		stdout: SplitParser {
			onRead: refresh.restart()
		}
		onExited: again.restart()
	}

	// the connection went (i3 restarted or reloaded): back in a moment, and reread meanwhile
	Timer {
		id: again

		interval: 1000
		onTriggered: {
			events.running = true;
			refresh.restart();
		}
	}

	Timer {
		id: refresh

		interval: 40
		running: true
		onTriggered: {
			workspaceList.running = true;
			tree.running = true;
		}
	}

	Process {
		id: workspaceList

		command: [root.msg, "-t", "get_workspaces"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					root.workspaces = JSON.parse(text).filter(w => w.num > 0).map(w => ({ num: w.num, name: w.name, focused: w.focused, visible: w.visible, urgent: w.urgent, output: w.output })).sort((a, b) => a.num - b.num);
				} catch (e) {}
			}
		}
	}

	// scratchpad windows keep a scratchpad_state other than "none", hidden in __i3_scratch or shown
	Process {
		id: tree

		command: [root.msg, "-t", "get_tree"]
		stdout: StdioCollector {
			onStreamFinished: {
				let total = 0, shown = 0;
				const walk = (node, hidden) => {
					if (node.name === "__i3_scratch")
						hidden = true;
					if ((node.window || node.app_id !== undefined && node.pid) && node.scratchpad_state && node.scratchpad_state !== "none") {
						total++;
						if (!hidden)
							shown++;
					}
					for (const child of [...(node.nodes ?? []), ...(node.floating_nodes ?? [])])
						walk(child, hidden);
				};
				try {
					walk(JSON.parse(text), false);
					root.scratchpad = total;
					root.scratchpadShown = shown;
				} catch (e) {}
			}
		}
	}
}
