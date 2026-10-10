pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// TLP's power profile (the control center's chips) and the battery's charge limit (Settings →
// Power), through desktop-power: read from TLP's state and the battery, changed without a password
// once `packages/system.sh power` allowed it (else the polkit prompt asks). Reread on plugging in
// or out (TLP switches the profile then) and every few seconds.
Singleton {
	id: root

	property string profile: "" // performance, balanced, power-saver; "" without TLP
	property int limit: 0 // the charge limit in %; 0 without a battery that has one
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
		reader.running = true;
	}

	function run(command: var): void {
		doer.command = command;
		doer.running = true;
	}

	Connections {
		target: Battery

		function onChargingChanged(): void {
			settle.restart();
		}
	}

	// TLP switches a moment after the plug
	Timer {
		id: settle

		interval: 1500
		onTriggered: root.refresh()
	}

	Timer {
		interval: 10000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: root.refresh()
	}

	Process {
		id: reader

		command: ["desktop-power", "state"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const state = JSON.parse(text);
					root.profile = state.profile;
					root.limit = state.limit;
				} catch (e) {}
			}
		}
	}

	Process {
		id: doer

		onExited: root.refresh()
	}
}
