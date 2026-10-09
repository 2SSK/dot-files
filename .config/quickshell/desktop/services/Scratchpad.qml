pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io

// How many windows sit in the i3/sway scratchpad, from the window tree, re-read after window events.
Singleton {
	id: root

	property int count: 0

	function show(): void {
		I3.dispatch("scratchpad show");
	}

	// the I3 singleton only follows workspace events; windows moving in and out need their own
	I3IpcListener {
		subscriptions: ["window", "workspace"]
		onIpcEvent: refresh.restart()
	}

	// several events often come at once (a move fires a few): read the tree once they've settled
	Timer {
		id: refresh

		interval: 120
		running: true
		onTriggered: tree.running = true
	}

	Process {
		id: tree

		command: [Quickshell.env("SWAYSOCK") ? "swaymsg" : "i3-msg", "-t", "get_tree"]
		stdout: StdioCollector {
			onStreamFinished: {
				const find = node => node.name === "__i3_scratch" ? node : [...(node.nodes ?? []), ...(node.floating_nodes ?? [])].map(find).find(n => n) ?? null;
				const scratch = find(JSON.parse(text));
				root.count = scratch ? (scratch.floating_nodes ?? []).length + (scratch.nodes ?? []).length : 0;
			}
		}
	}
}
