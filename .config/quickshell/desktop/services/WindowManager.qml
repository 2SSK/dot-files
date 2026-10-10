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

	// one line per event: workspace and output events reread the workspaces, window events that
	// change the list reread the tree
	Process {
		id: events

		running: true
		// one event per line: i3-msg prints them so, swaymsg spreads each over many (jq joins them)
		command: root.msg === "swaymsg" ? ["sh", "-c", `swaymsg -t subscribe -m '["workspace","window","output","mode"]' | jq -c --unbuffered .`] : [root.msg, "-t", "subscribe", "-m", '["workspace","window","output","mode"]']
		stdout: SplitParser {
			onRead: line => {
				let data;
				try {
					data = JSON.parse(line);
				} catch (e) {
					return;
				}
				if (data.container) {
					root.windowEvent(data);
					// the tree only for what changes the window list or the scratchpad; focus (it follows
					// the mouse) and titles (a terminal's change all the time) Windows patches itself
					if (["new", "close", "move", "floating", "urgent"].includes(data.change))
						treeLater.restart();
					if (data.change === "urgent" || data.change === "move")
						workspacesLater.restart();
				} else if (data.pango_markup !== undefined) {
					root.mode = data.change; // a mode event
				} else {
					workspacesLater.restart(); // a workspace or output event
					if (data.change === "reload")
						modeNow.running = true; // back to the default mode, unannounced
					else if (data.current === undefined && data.change === "unspecified")
						rehomeLater.restart(); // a screen came or went: workspaces back to their screens
				}
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
			workspacesLater.restart();
			treeLater.restart();
			modeNow.running = true;
		}
	}

	// the binding mode as it is now: a reload (sway's, i3's) resets it without a mode event, which
	// left the bar showing "VM keys" after one
	Process {
		id: modeNow

		running: true
		command: [root.msg, "-t", "get_binding_state"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					root.mode = JSON.parse(text).name;
				} catch (e) {}
			}
		}
	}

	// several events often come at once (a move fires a few): each read waits for them to settle
	Timer {
		id: workspacesLater

		interval: 40
		running: true
		onTriggered: workspaceList.running = true
	}

	// once the screens have settled: the window manager applies workspaces.conf's screens only to
	// new workspaces, so desktop-displays moves the ones a monitor's absence left elsewhere
	Timer {
		id: rehomeLater

		interval: 1500
		onTriggered: Quickshell.execDetached(["desktop-displays", "rehome"])
	}

	Timer {
		id: treeLater

		interval: 40
		running: true
		onTriggered: tree.running = true
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
