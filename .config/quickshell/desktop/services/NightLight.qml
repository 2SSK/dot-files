pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// A warmer screen at night, through gammastep (X11 and Wayland alike): on by hand from the control
// center, or by itself between nightLight.from and .to when nightLight.schedule is on (a click
// during those hours turns it off until they end). nightLight.temperature sets how warm. gammastep
// fades in as it starts and back as it stops.
Singleton {
	id: root

	property bool available: false
	property bool manual: false // on now, by hand
	property bool skipped: false // off by hand during the scheduled hours
	property bool inHours: false
	readonly property int temperature: Config.nightLight.temperature
	readonly property bool scheduled: Config.nightLight.schedule && inHours
	readonly property bool active: available && (manual || scheduled && !skipped)

	function toggle(): void {
		if (active) {
			manual = false;
			skipped = scheduled;
		} else {
			manual = true;
			skipped = false;
		}
	}

	function minutes(hm: string): int {
		const m = /^(\d{1,2}):(\d{2})$/.exec(hm.trim());
		return m ? Number(m[1]) * 60 + Number(m[2]) : -1;
	}

	function check(): void {
		const now = new Date();
		const t = now.getHours() * 60 + now.getMinutes();
		const from = minutes(Config.nightLight.from), to = minutes(Config.nightLight.to);
		const was = inHours;
		inHours = from >= 0 && to >= 0 && (from < to ? t >= from && t < to : t >= from || t < to);
		if (was && !inHours)
			skipped = false; // the hours ended: next evening it comes on again
	}

	onActiveChanged: restart.restart()
	onTemperatureChanged: if (active) restart.restart()

	Process {
		running: true
		command: ["sh", "-c", "command -v gammastep"]
		onExited: code => root.available = code === 0
	}

	// a warm screen for as long as this runs: -l 0:0 and the same day and night warmth, so the
	// position of the sun doesn't matter
	Process {
		id: gamma

		command: ["gammastep", "-P", "-l", "0:0", "-t", `${root.temperature}:${root.temperature}`]
	}

	// stop, then start again with the new warmth (or not at all)
	Timer {
		id: restart

		interval: 50
		onTriggered: {
			gamma.running = false;
			if (root.active)
				again.restart();
		}
	}

	Timer {
		id: again

		interval: 300
		onTriggered: gamma.running = root.active
	}

	Timer {
		interval: 60000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: root.check()
	}

	Connections {
		target: Config.nightLight

		function onFromChanged(): void {
			root.check();
		}
		function onToChanged(): void {
			root.check();
		}
	}
}
