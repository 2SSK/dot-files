pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Alarms, kept in ~/.local/share/desktop/alarms.json. An entry's fired is the last minute it rang
// (yyyy-MM-ddTHH:mm) and snooze when a snoozed one rings again, in ms since the epoch (0 for none).
Singleton {
	id: root

	readonly property var alarms: [...adapter.alarms].sort((a, b) => a.time < b.time ? -1 : 1)
	property var ringing: null
	readonly property string sound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

	function add(time: string, label: string, repeat: string, date: var): bool {
		if (!/^\d{1,2}:\d{2}$/.test(time.trim()))
			return false;
		const day = repeat === "once" && date ? Qt.formatDate(date, "yyyy-MM-dd") : "";
		save([...adapter.alarms, { id: `${Date.now()}-${Math.floor(Math.random() * 1e6)}`, time: time.trim().padStart(5, "0"), label: label.trim() || "Alarm", repeat, date: day, enabled: true, fired: "", snooze: 0 }]);
		return true;
	}

	function ringsOn(alarm: var, day: date): bool {
		if (alarm.repeat === "daily")
			return true;
		if (alarm.repeat === "weekdays")
			return day.getDay() >= 1 && day.getDay() <= 5;
		return (alarm.date || Qt.formatDate(new Date(), "yyyy-MM-dd")) === Qt.formatDate(day, "yyyy-MM-dd");
	}

	function on(day: date): var {
		return alarms.filter(a => a.enabled && ringsOn(a, day));
	}

	function update(id: string, change: var): void {
		save(adapter.alarms.map(a => a.id === id ? Object.assign({}, a, change) : a));
	}

	function remove(id: string): void {
		save(adapter.alarms.filter(a => a.id !== id));
	}

	function stop(): void {
		ringing = null;
	}

	function snooze(): void {
		if (ringing)
			update(ringing.id, { snooze: Date.now() + 5 * 60000 });
		ringing = null;
	}

	function save(list: var): void {
		adapter.alarms = list;
		file.writeAdapter();
	}

	function ring(alarm: var): void {
		ringing = alarm;
		rang.restart();
		chime.running = false;
		chime.running = true;
	}

	Timer {
		interval: 15000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			const now = new Date();
			const minute = Qt.formatDateTime(now, "yyyy-MM-ddTHH:mm");
			const hm = Qt.formatTime(now, "HH:mm");
			const weekday = now.getDay() >= 1 && now.getDay() <= 5;
			for (const alarm of adapter.alarms) {
				if (alarm.snooze && Date.now() >= alarm.snooze) {
					root.update(alarm.id, { snooze: 0 });
					root.ring(alarm);
					return;
				}
				if (!alarm.enabled || alarm.time !== hm || alarm.fired === minute)
					continue;
				if (alarm.repeat === "weekdays" && !weekday || alarm.repeat === "once" && alarm.date && alarm.date !== Qt.formatDate(now, "yyyy-MM-dd"))
					continue;
				root.update(alarm.id, { fired: minute, enabled: alarm.repeat !== "once" });
				root.ring(alarm);
				return;
			}
		}
	}

	Process {
		id: chime

		command: ["pw-play", root.sound]
		onExited: if (root.ringing) again.restart()
	}

	Timer {
		id: again

		interval: 1500
		onTriggered: if (root.ringing) chime.running = true
	}

	Timer {
		id: rang

		interval: 5 * 60000
		onTriggered: root.ringing = null
	}

	FileView {
		id: file

		path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop/alarms.json"
		blockLoading: true
		watchChanges: true
		onFileChanged: reload()
		printErrors: false

		JsonAdapter {
			id: adapter

			property var alarms: []
		}
	}
}
