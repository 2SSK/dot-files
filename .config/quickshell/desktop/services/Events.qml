pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Calendar events, kept on this machine in ~/.local/share/desktop/events.json: { id, date
// (yyyy-MM-dd), time (HH:mm, or "" for all day), text, notified }. One with a time is a reminder:
// a notification when it's due, once.
Singleton {
	id: root

	readonly property var events: adapter.events

	function key(date: date): string {
		return Qt.formatDate(date, "yyyy-MM-dd");
	}

	// a day's events, all-day ones first, then by time
	function on(date: date): var {
		const k = key(date);
		return events.filter(e => e.date === k).sort((a, b) => (a.time || "") < (b.time || "") ? -1 : 1);
	}

	function has(date: date): bool {
		const k = key(date);
		return events.some(e => e.date === k);
	}

	function add(date: date, time: string, text: string): void {
		if (!text.trim())
			return;
		const t = /^\d{1,2}:\d{2}$/.test(time.trim()) ? time.trim().padStart(5, "0") : "";
		save([...events, { id: `${Date.now()}-${Math.floor(Math.random() * 1e6)}`, date: key(date), time: t, text: text.trim(), notified: false }]);
	}

	function remove(id: string): void {
		save(events.filter(e => e.id !== id));
	}

	function save(list: var): void {
		adapter.events = list;
		file.writeAdapter();
	}

	// reminders: due ones (in the last hour, so a late start still shows them) notify once
	Timer {
		interval: 30000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			const now = new Date();
			const due = root.events.filter(e => {
				if (!e.time || e.notified)
					return false;
				const when = new Date(`${e.date}T${e.time}:00`);
				return when <= now && now - when < 3600000;
			});
			if (due.length === 0)
				return;
			for (const e of due)
				Quickshell.execDetached(["notify-send", "-a", "Calendar", "-u", "critical", e.text, `${Qt.formatDate(new Date(e.date + "T00:00:00"), "dddd, d MMMM")} at ${e.time}`]);
			root.save(root.events.map(e => due.includes(e) ? Object.assign({}, e, { notified: true }) : e));
		}
	}

	FileView {
		id: file

		path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop/events.json"
		blockLoading: true
		watchChanges: true
		onFileChanged: reload()
		printErrors: false

		JsonAdapter {
			id: adapter

			property var events: []
		}
	}
}
