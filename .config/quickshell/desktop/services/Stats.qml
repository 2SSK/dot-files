pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory use (/proc) and the CPU temperature (hwmon: coretemp, k10temp, ...), every 2 s,
// with the last two minutes of each for graphs; the root disk, uptime and load for the monitor page.
// The GPU, network, uptime and load are only read while that page is open (detail).
// Also the GPU (an AMD card's busy %, else Intel's clock against its top clock, from sysfs) and the
// network (the real interfaces' bytes in /proc/net/dev, as speeds). A discrete NVIDIA card is only
// asked (nvidia-smi) while it's awake anyway and the monitor page is open (detail): asking wakes
// it, and polling would keep it awake.
Singleton {
	id: root

	property real cpu: 0 // 0–1
	property real memUsed: 0 // GiB
	property real memTotal: 0
	readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0 // 0–1
	property real temp: -1 // °C; -1 without a sensor
	property string tempFile: ""
	property var cpuHistory: [] // the last 60 samples, oldest first
	property var memHistory: []
	property var tempHistory: []
	property real diskUsed: 0 // GiB, of /
	property real diskTotal: 0
	property real uptime: 0 // s
	property string load: ""
	property string gpuName: "" // "Intel", "AMD"; "" without one found
	property string gpuFile: "" // the busy % (AMD) or the current clock (Intel)
	property real gpuMaxFreq: 0 // MHz (Intel)
	property real gpu: 0 // 0–1
	property real gpuFreq: 0 // MHz (Intel)
	property var gpuHistory: []
	property string dgpuStatus: "" // the NVIDIA card's runtime power status file; "" without one
	property bool dgpuAwake: false
	property string dgpu: "" // its load and temperature while awake, for the monitor page
	property int detail: 0 // monitor pages open: then the NVIDIA card may be asked
	property real netDown: 0 // bytes/s
	property real netUp: 0
	property var netDownHistory: []
	property var netUpHistory: []
	property var netPrevious: null

	function remember(list: var, value: real): var {
		return [...list, value].slice(-60);
	}
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
			tempHistory = remember(tempHistory, temp);
		}
		cpuHistory = remember(cpuHistory, cpu);
		memHistory = remember(memHistory, mem);

		// the rest only the monitor page shows: read while it's open
		if (detail === 0)
			return;

		if (gpuFile) {
			gpuReading.reload();
			const n = Number(gpuReading.text().trim());
			gpuFreq = gpuName === "Intel" ? n : 0;
			gpu = gpuName === "Intel" ? (gpuMaxFreq > 0 ? Math.min(1, n / gpuMaxFreq) : 0) : n / 100;
			gpuHistory = remember(gpuHistory, gpu);
		}
		if (dgpuStatus) {
			dgpuState.reload();
			dgpuAwake = dgpuState.text().trim() === "active";
			if (dgpuAwake && detail > 0)
				nvidia.running = true;
			else if (!dgpuAwake)
				dgpu = "";
		}

		netDev.reload();
		let rx = 0, tx = 0;
		for (const line of netDev.text().split("\n").slice(2)) {
			const [name, rest] = line.split(":");
			if (!rest || !/^(wl|en|eth|ww)/.test(name.trim()))
				continue;
			const f = rest.trim().split(/\s+/).map(Number);
			rx += f[0];
			tx += f[8];
		}
		const now = Date.now();
		if (netPrevious && now > netPrevious.time) {
			const s = (now - netPrevious.time) / 1000;
			netDown = Math.max(0, (rx - netPrevious.rx) / s);
			netUp = Math.max(0, (tx - netPrevious.tx) / s);
			netDownHistory = remember(netDownHistory, netDown);
			netUpHistory = remember(netUpHistory, netUp);
		}
		netPrevious = { rx, tx, time: now };

		uptimeFile.reload();
		uptime = Number(uptimeFile.text().split(" ")[0]);
		loadFile.reload();
		load = loadFile.text().split(" ").slice(0, 3).join("  ");
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

	// the GPUs: an AMD card's busy %, else Intel's clocks; a discrete NVIDIA card's power status
	Process {
		running: true
		command: ["sh", "-c", 'for c in /sys/class/drm/card[0-9]*; do d=$c/device; case $(cat $d/vendor 2>/dev/null) in 0x1002) [ -r $d/gpu_busy_percent ] && echo "gpu AMD $d/gpu_busy_percent 0";; 0x8086) [ -r $c/gt_act_freq_mhz ] && echo "gpu Intel $c/gt_act_freq_mhz $(cat $c/gt_max_freq_mhz)";; 0x10de) echo "dgpu $(readlink -f $d)/power/runtime_status";; esac; done']
		stdout: StdioCollector {
			onStreamFinished: {
				for (const line of text.trim().split("\n")) {
					const f = line.split(" ");
					if (f[0] === "gpu" && !root.gpuFile) {
						root.gpuName = f[1];
						root.gpuFile = f[2];
						root.gpuMaxFreq = Number(f[3]);
					} else if (f[0] === "dgpu") {
						root.dgpuStatus = f[1];
					}
				}
			}
		}
	}

	FileView {
		id: gpuReading

		path: root.gpuFile
		blockLoading: true
		printErrors: false
	}

	FileView {
		id: dgpuState

		path: root.dgpuStatus
		blockLoading: true
		printErrors: false
	}

	Process {
		id: nvidia

		command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
		stdout: StdioCollector {
			onStreamFinished: {
				const [use, temp] = text.trim().split(",").map(v => v.trim());
				root.dgpu = use ? `${use}%  ${temp} °C` : "";
			}
		}
	}

	FileView {
		id: netDev

		path: "/proc/net/dev"
		blockLoading: true
	}

	FileView {
		id: uptimeFile

		path: "/proc/uptime"
		blockLoading: true
	}

	FileView {
		id: loadFile

		path: "/proc/loadavg"
		blockLoading: true
	}

	// the root disk, every 30 s
	Process {
		id: disk

		command: ["df", "-B1", "--output=used,size", "/"]
		stdout: StdioCollector {
			onStreamFinished: {
				const [used, size] = text.trim().split("\n")[1].trim().split(/\s+/).map(Number);
				root.diskUsed = used / 1073741824;
				root.diskTotal = size / 1073741824;
			}
		}
	}

	Timer {
		interval: 30000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: disk.running = true
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
