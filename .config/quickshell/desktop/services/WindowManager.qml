pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The shell's line to i3 or sway, through a long-lived subscribe and i3-msg rather than Quickshell.I3,
// whose connections drop and leave the bar stale and commands ignored.
Singleton {
	id: root

	readonly property string msg: Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg"
	property var workspaces: [] // { num, name, focused, visible, urgent, output }, by number
	property int scratchpad: 0 // windows that belong to the scratchpad
	property int scratchpadShown: 0 // of those, the ones out on a workspace now
	readonly property string focusedOutput: workspaces.find(w => w.focused)?.output ?? ""
	property string mode: "default" // i3's binding mode (passthrough, resize, power, switcher...)

	signal windowEvent(var data) // i3's window events: { change, container: { id, name, ... } }
	signal treeRead(var tree)

	function command(cmd: string): void {
		Quickshell.execDetached([msg, "-q", cmd]);
	}

	function switchTo(num: int): void {
		command(`workspace number ${num}`);
	}

	// the floating group (desktop-scratch), else the scratchpad as sway and i3 have it
	function showScratchpad(): void {
		Quickshell.execDetached(["desktop-scratch", "toggle"]);
	}

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
					// focus follows the mouse and terminals retitle constantly, so Windows patches those itself
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

	// i3 restarted or reloaded and the connection went
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

	// a reload resets the binding mode without a mode event, which left the bar showing "VM keys"
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

	Process {
		id: tree

		command: [root.msg, "-t", "get_tree"]
		stdout: StdioCollector {
			onStreamFinished: {
				let total = 0, shown = 0;
				// i3 marks the floating container around a scratchpad window, not the window itself; the
				// floating group (desktop-scratch) counts as the windows in it
				const windows = node => (node.nodes ?? []).length + (node.floating_nodes ?? []).length === 0 ? 1
					: [...(node.nodes ?? []), ...(node.floating_nodes ?? [])].reduce((n, c) => n + windows(c), 0);
				const walk = (node, hidden) => {
					if (node.name === "__i3_scratch")
						hidden = true;
					if (node.scratchpad_state && node.scratchpad_state !== "none") {
						const n = (node.marks ?? []).includes("_scratch_workspace") ? windows(node) : 1;
						total += n;
						if (!hidden)
							shown += n;
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
