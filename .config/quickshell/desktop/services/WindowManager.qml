pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The shell's line to i3 (or sway): the workspaces, the focused monitor, the scratchpad, window
// events, and commands. Not through Quickshell.I3, whose connections drop and then leave the bar
// stale and commands ignored: a long-lived `i3-msg -t subscribe -m` says when something changed
// (started again if i3 restarts or the connection goes), then the workspaces and the tree are
// reread; commands go through i3-msg.
Singleton {
	id: root

	readonly property string msg: Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg"
	property var workspaces: [] // { num, name, focused, visible, urgent, output }, by number
	property int scratchpad: 0 // windows that belong to the scratchpad
	property int scratchpadShown: 0 // of those, the ones out on a workspace now
	readonly property string focusedOutput: workspaces.find(w => w.focused)?.output ?? ""
	property string mode: "default" // i3's binding mode (passthrough, resize, power, switcher...)

	signal windowEvent(var data) // i3's window events: { change, container: { id, name, ... } }
	signal treeRead(var tree) // the whole window tree, reread after each change

	// a command for the window manager: through i3-msg, as Quickshell.I3's own connection drops them
	function command(cmd: string): void {
		Quickshell.execDetached([msg, "-q", cmd]);
	}

	function switchTo(num: int): void {
		command(`workspace number ${num}`);
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
			onRead: line => {
				refresh.restart();
				try {
					const data = JSON.parse(line);
					if (data.container)
						root.windowEvent(data);
					else if (data.pango_markup !== undefined)
						root.mode = data.change; // a mode event
				} catch (e) {}
			}
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

	// the tree: the scratchpad (a scratchpad window's floating container keeps a scratchpad_state
	// other than "none", hidden in __i3_scratch or shown), and for the window switcher (treeRead)
	Process {
		id: tree

		command: [root.msg, "-t", "get_tree"]
		stdout: StdioCollector {
			onStreamFinished: {
				let total = 0, shown = 0;
				// i3 marks the floating container around a scratchpad window, not the window itself
				const walk = (node, hidden) => {
					if (node.name === "__i3_scratch")
						hidden = true;
					if (node.scratchpad_state && node.scratchpad_state !== "none") {
						total++;
						if (!hidden)
							shown++;
						return;
					}
					for (const child of [...(node.nodes ?? []), ...(node.floating_nodes ?? [])])
						walk(child, hidden);
				};
				try {
					const parsed = JSON.parse(text);
					walk(parsed, false);
					root.scratchpad = total;
					root.scratchpadShown = shown;
					root.treeRead(parsed);
				} catch (e) {}
			}
		}
	}
}
