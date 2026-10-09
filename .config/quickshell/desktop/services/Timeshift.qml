pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Timeshift's snapshots for the settings page, through desktop-timeshift: the list (without a
// password once `packages/system.sh timeshift` allowed it; else on request, asking), making one
// with a comment, deleting one (both ask for the password: the shell's polkit prompt), and
// Timeshift's own app for restoring.
Singleton {
	id: root

	property var info: ({}) // { device, mode, status, free }
	property var snapshots: [] // { name, tags, comment }, newest first
	property string state: "" // "", loading, rule (no passwordless list), error, working
	property string working: "" // what's being done, while state is working

	function refresh(ask: bool): void {
		if (state === "working")
			return;
		state = "loading";
		lister.command = ["desktop-timeshift", "list", ...(ask ? ["--ask"] : [])];
		lister.running = true;
	}

	function create(comment: string): void {
		run(["desktop-timeshift", "create", comment.trim() || "From the desktop"], "Making a snapshot…");
	}

	function remove(name: string): void {
		run(["desktop-timeshift", "delete", name], "Deleting " + name + "…");
	}

	function openApp(): void {
		Quickshell.execDetached(["timeshift-launcher"]);
	}

	function run(command: var, what: string): void {
		if (state === "working")
			return;
		working = what;
		state = "working";
		doer.command = command;
		doer.running = true;
	}

	Process {
		id: lister

		stdout: StdioCollector {
			onStreamFinished: {
				if (!text.trim())
					return;
				try {
					const d = JSON.parse(text);
					root.snapshots = d.snapshots;
					root.info = { device: d.device, mode: d.mode, status: d.status, free: d.free };
					root.state = "";
				} catch (e) {
					root.state = "error";
				}
			}
		}
		onExited: code => {
			if (code === 3)
				root.state = "rule";
			else if (code !== 0)
				root.state = "error";
		}
	}

	Process {
		id: doer

		onExited: code => {
			Quickshell.execDetached(["notify-send", "-a", "Timeshift", code === 0 ? "Done" : "Didn't finish", code === 0 ? root.working.replace("…", "") : root.working.replace("…", "") + " was cancelled or failed"]);
			root.state = "";
			root.refresh(false);
		}
	}
}
