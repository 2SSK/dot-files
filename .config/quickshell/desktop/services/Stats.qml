pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory use (/proc) and the CPU temperature (hwmon: coretemp, k10temp, ...), every 2 s.
Singleton {
	id: root

	property real cpu: 0 // 0–1
	property real memUsed: 0 // GiB
	property real memTotal: 0
	readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0 // 0–1
	property real temp: -1 // °C; -1 without a sensor
	property string tempFile: ""
	property var previous: null

	function update(): void {
		const times = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
		const idle = times[3] + times[4]; // idle + iowait
		const total = times.reduce((sum, t) => sum + t, 0);
		if (previous && total > previous.total)
			cpu = 1 - (idle - previous.idle) / (total - previous.total);
		previous = { idle, total };

		const kib = key => Number((meminfo.text().match(new RegExp(`^${key}:\\s+(\\d+)`, "m")) ?? [0, 0])[1]);
		memTotal = kib("MemTotal") / 1048576;
		memUsed = memTotal - kib("MemAvailable") / 1048576;

		if (tempFile) {
			thermal.reload();
			temp = Number(thermal.text().trim()) / 1000;
		}
	}

	FileView {
		id: stat

		path: "/proc/stat"
		blockLoading: true
	}

	// the CPU package sensor, else the x86 package thermal zone
	Process {
		running: true
		command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in coretemp|k10temp|zenpower|cpu_thermal) echo $h/temp1_input; exit;; esac; done; for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo $z/temp && exit; done"]
		stdout: StdioCollector {
			onStreamFinished: root.tempFile = text.trim()
		}
	}

	FileView {
		id: thermal

		path: root.tempFile
		blockLoading: true
		printErrors: false
	}

	FileView {
		id: meminfo

		path: "/proc/meminfo"
		blockLoading: true
	}

	Timer {
		interval: 2000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			stat.reload();
			meminfo.reload();
			root.update();
		}
	}
}
