pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory use, read from /proc every 2 s.
Singleton {
	id: root

	property real cpu: 0 // 0–1
	property real memUsed: 0 // GiB
	property real memTotal: 0
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
	}

	FileView {
		id: stat

		path: "/proc/stat"
		blockLoading: true
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
