pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// TLP's power profile (the control center's chips) and the battery's charge limit (Settings →
// Power). Read straight from the files: TLP's state (/run/tlp/last_pwr, watched) and the battery's
// limit in sysfs (which can't be watched: reread on plugging in or out, after a change, and when a
// page showing it opens). Changes go through desktop-power: without a password once
// `packages/system.sh power` allowed it, else the polkit prompt asks.
Singleton {
	id: root

	readonly property var profiles: ["performance", "balanced", "power-saver"] // TLP's order in last_pwr
	property string profile: "" // performance, balanced, power-saver; "" without TLP
	property int limit: 0 // the charge limit in %; 0 without a battery that has one
	property string limitFile: ""
	readonly property bool available: profile !== ""

	function setProfile(name: string): void {
		profile = name; // at once; the reread after corrects it if TLP refused
		run(["desktop-power", "profile", name]);
	}

	function setLimit(percent: int): void {
		limit = percent;
		run(["desktop-power", "limit", String(percent)]);
	}

	function refresh(): void {
		state.reload();
		if (limitFile) {
			limitView.reload();
			limit = Number(limitView.text().trim()) || 0;
		}
	}

	function run(command: var): void {
		doer.command = command;
		doer.running = true;
	}

	// TLP switches a moment after the plug
	Connections {
		target: Battery

		function onChargingChanged(): void {
			settle.restart();
		}
	}

	Timer {
		id: settle

		interval: 1500
		onTriggered: root.refresh()
	}

	FileView {
		id: state

		path: "/run/tlp/last_pwr"
		watchChanges: true
		printErrors: false
		onFileChanged: reload()
		onLoaded: root.profile = root.profiles[Number(text().trim().split(/\s+/)[0])] ?? ""
		onLoadFailed: root.profile = ""
	}

	// the first battery with a charge limit
	Process {
		running: true
		command: ["sh", "-c", "ls /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null | head -1"]
		stdout: StdioCollector {
			onStreamFinished: {
				root.limitFile = text.trim();
				root.refresh();
			}
		}
	}

	FileView {
		id: limitView

		path: root.limitFile
		blockLoading: true
		printErrors: false
	}

	Process {
		id: doer

		onExited: root.refresh()
	}
}
