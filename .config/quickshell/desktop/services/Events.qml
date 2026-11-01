pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Calendar events, kept on this machine in ~/.local/share/desktop/events.json. One with a time is a
// reminder: a heads-up calendar.lead minutes before (if set), then a notification at the time. One may
// repeat (daily, weekdays, weekly, monthly) from its date on; each day it happens is an occurrence, and
// alerts are kept per occurrence (warned/notifiedOn: the day last alerted). A time may carry an end
// ("10:30-11:15"); without one the timeline gives it half an hour.
Singleton {
	id: root

	readonly property var events: adapter.events
	readonly property var repeats: ({ "": "Once", daily: "Every day", weekdays: "Weekdays", weekly: "Every week", monthly: "Every month" })
	// the next timed occurrence starting within calendar.nextUp minutes: { event, date, at (Date) }, for the bar
	property var nextUp: null

	function key(date: date): string {
		return Qt.formatDate(date, "yyyy-MM-dd");
	}

	function dateOf(k: string): date {
		return new Date(k + "T00:00:00");
	}

	// whether the event happens on that day (a "yyyy-MM-dd")
	function occurs(e: var, k: string): bool {
		if (!e.repeat)
			return e.date === k;
		if (k < e.date)
			return false;
		const day = dateOf(k), first = dateOf(e.date);
		switch (e.repeat) {
		case "daily":
			return true;
		case "weekdays":
			return day.getDay() !== 0 && day.getDay() !== 6;
		case "weekly":
			return day.getDay() === first.getDay();
		case "monthly":
			return day.getDate() === first.getDate();
		}
		return false;
	}

	// an occurrence as the pages list it: the event's fields, its day, and whether it's been and gone
	function occurrence(e: var, k: string): var {
		return Object.assign({}, e, { date: k, done: e.notifiedOn === k || (!e.repeat && !!e.notified) });
	}

	function on(date: date): var {
		const k = key(date);
		return events.filter(e => occurs(e, k)).map(e => occurrence(e, k)).sort((a, b) => (a.time || "") < (b.time || "") ? -1 : 1);
	}

	function has(date: date): bool {
		const k = key(date);
		return events.some(e => occurs(e, k));
	}

	// the occurrences from one day to another (both included), by day and time
	function between(from: date, to: date): var {
		const out = [];
		for (let d = new Date(from); d <= to; d.setDate(d.getDate() + 1)) {
			const k = key(d);
			for (const e of events.filter(e => occurs(e, k)))
				out.push(occurrence(e, k));
		}
		return out.sort((a, b) => a.date + (a.time || "") < b.date + (b.time || "") ? -1 : 1);
	}

	// "10:30-11:15" → { time: "10:30", end: "11:15" }; "9:5" or nonsense → no time
	function times(text: string): var {
		const m = text.trim().match(/^(\d{1,2}):(\d{2})(?:\s*[-–]\s*(\d{1,2}):(\d{2}))?$/);
		if (!m || +m[1] > 23 || +m[2] > 59)
			return { time: "", end: "" };
		const time = `${m[1].padStart(2, "0")}:${m[2]}`;
		const end = m[3] !== undefined && +m[3] <= 23 && +m[4] <= 59 ? `${m[3].padStart(2, "0")}:${m[4]}` : "";
		return { time, end: end > time ? end : "" };
	}

	// minutes since midnight
	function minutes(hhmm: string): int {
		const [h, m] = hhmm.split(":").map(Number);
		return h * 60 + m;
	}

	function add(date: date, time: string, text: string, repeat: string): void {
		if (!text.trim())
			return;
		const t = times(time);
		save([...events, { id: `${Date.now()}-${Math.floor(Math.random() * 1e6)}`, date: key(date), time: t.time, end: t.end, repeat: repeat ?? "", text: text.trim(), notified: false }]);
	}

	// a changed text, time or repeat; a new time is due again (it alerts once more)
	function update(id: string, time: string, text: string, repeat: var): void {
		if (!text.trim())
			return;
		const t = times(time);
		save(events.map(e => e.id !== id ? e : Object.assign({}, e, { time: t.time, end: t.end, text: text.trim(), repeat: repeat === undefined ? e.repeat ?? "" : repeat }, e.time === t.time ? {} : { notified: false, notifiedOn: "", warned: "" })));
	}

	function remove(id: string): void {
		save(events.filter(e => e.id !== id));
	}

	function save(list: var): void {
		adapter.events = list;
		file.writeAdapter();
	}

	function notify(e: var, body: string): void {
		Quickshell.execDetached(["notify-send", "-a", "Calendar", "-u", "critical", e.text, body]);
	}

	// today's timed occurrences, their heads-up and their notification (one due in the last hour still
	// notifies, so a late start shows it), and what the bar names next: every half minute, and as the
	// events change (loaded, added, edited)
	function check(): void {
		const now = new Date();
		const k = root.key(now);
		const lead = (Config.calendar?.lead ?? 10) * 60000; // the settings may not be read yet at startup
		const changes = {};
		let next = null;
		for (const e of root.events) {
			if (!e.time || !root.occurs(e, k))
				continue;
			const at = new Date(`${k}T${e.time}:00`);
			const done = e.notifiedOn === k || (!e.repeat && e.notified);
			if (!done && at <= now && now - at < 3600000) {
				root.notify(e, `Now · ${e.time}${e.end ? "–" + e.end : ""}`);
				changes[e.id] = Object.assign(changes[e.id] ?? {}, { notifiedOn: k, notified: !e.repeat });
			} else if (!done && lead > 0 && at > now && at - now <= lead && e.warned !== k) {
				root.notify(e, `In ${Math.max(1, Math.round((at - now) / 60000))} min · ${e.time}`);
				changes[e.id] = Object.assign(changes[e.id] ?? {}, { warned: k });
			}
			if (at > now && at - now <= (Config.calendar?.nextUp ?? 15) * 60000 && (!next || at < next.at))
				next = { event: e, date: k, at };
		}
		root.nextUp = next;
		if (Object.keys(changes).length)
			root.save(root.events.map(e => changes[e.id] ? Object.assign({}, e, changes[e.id]) : e));
	}

	onEventsChanged: Qt.callLater(check)

	Timer {
		interval: 30000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: root.check()
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
