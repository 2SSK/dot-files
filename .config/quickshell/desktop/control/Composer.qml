pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.widgets

// One line to add an event, reminder or alarm to a day, with its time (a reminder's may run on:
// "09:30-10:15"), its text and how often. Enter adds it.
Column {
	id: root

	property date day: new Date()
	property bool datePicker: false
	property string kind: "reminder" // event, reminder or alarm
	property string repeat: "once" // an alarm's
	property string eventRepeat: "" // an event's or reminder's (Events.repeats)
	property bool picking: false
	readonly property var kinds: ({ event: { label: "Event", glyph: "calendar" }, reminder: { label: "Reminder", glyph: "bell" }, alarm: { label: "Alarm", glyph: "alarm" } })
	readonly property var repeats: ({ once: "Once", daily: "Daily", weekdays: "Weekdays" })

	signal added

	function focusField(): void {
		(kind === "event" ? what : time).focusField();
	}

	// a reminder at that time ("14:00", from a click on the timeline's empty hour)
	function startAt(hhmm: string): void {
		kind = "reminder";
		time.text = hhmm;
		what.focusField();
	}

	function add(): void {
		const timed = kind !== "event";
		if (kind === "alarm" ? !/^\d{1,2}:\d{2}$/.test(time.text.trim()) : timed && !Events.times(time.text).time)
			return time.focusField();
		if (kind === "alarm")
			Alarms.add(time.text, what.text, repeat, day);
		else if (what.text.trim())
			Events.add(day, timed ? time.text : "", what.text, eventRepeat);
		else
			return what.focusField();
		time.text = "";
		what.text = "";
		eventRepeat = "";
		picking = false;
		added();
	}

	function step(map: var, key: string): string {
		const keys = Object.keys(map);
		return keys[(keys.indexOf(key) + 1) % keys.length];
	}

	spacing: 8

	Row {
		width: parent.width
		spacing: 8

		Chip {
			id: kindChip

			anchors.verticalCenter: parent.verticalCenter
			glyph: Icons.g(root.kinds[root.kind].glyph)
			label: root.kinds[root.kind].label
			onClicked: {
				root.kind = root.step(root.kinds, root.kind);
				root.focusField();
			}
		}

		Chip {
			id: dateChip

			visible: root.datePicker && !(root.kind === "alarm" && root.repeat !== "once")
			anchors.verticalCenter: parent.verticalCenter
			label: Qt.formatDate(root.day, "ddd d MMM")
			on: root.picking
			onClicked: root.picking = !root.picking
		}

		TextField {
			id: time

			visible: root.kind !== "event"
			width: root.kind === "alarm" ? 76 : 120
			height: 34
			placeholder: root.kind === "alarm" ? "09:30" : "09:30-10:15"
			onAccepted: root.add()
		}

		TextField {
			id: what

			width: parent.width - kindChip.width - (dateChip.visible ? dateChip.width + 8 : 0) - (time.visible ? time.width + 8 : 0) - (often.visible ? often.width + 8 : 0) - 8
			height: 34
			placeholder: root.kind === "alarm" ? "Label, and Enter" : "What, and Enter"
			onAccepted: root.add()
		}

		Chip {
			id: often

			anchors.verticalCenter: parent.verticalCenter
			label: root.kind === "alarm" ? root.repeats[root.repeat] : Events.repeats[root.eventRepeat]
			on: root.kind === "alarm" ? root.repeat !== "once" : root.eventRepeat !== ""
			onClicked: {
				if (root.kind === "alarm")
					root.repeat = root.step(root.repeats, root.repeat);
				else
					root.eventRepeat = root.step(Events.repeats, root.eventRepeat);
			}
		}
	}

	MonthGrid {
		visible: root.picking
		width: parent.width
		cellHeight: 30
		chosen: root.day
		onPicked: day => {
			root.day = day;
			root.picking = false;
			root.focusField();
		}
	}
}
