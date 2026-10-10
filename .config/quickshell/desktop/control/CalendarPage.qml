pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.settings
import qs.widgets

// The calendar, in two views (the header's buttons switch them):
//   Calendar: a month; the chosen day's events, reminders and the alarms ringing that day below,
//     and a small + that opens a line to add one to it (Composer).
//   Reminders & alarms: a line to add one on any day (its date chip opens a small month), then the
//     reminders coming up and every alarm, with its switch.
// Events and reminders are kept by Events, alarms by Alarms; ✕ (on hover) removes one.
Column {
	id: root

	property string view: "calendar"
	readonly property string title: view === "calendar" ? "Calendar" : "Reminders & alarms"
	readonly property var actions: [
		{ glyph: Icons.g("calendar"), on: view === "calendar", act: () => root.view = "calendar" },
		{ glyph: Icons.g("alarm"), on: view === "upcoming", act: () => root.view = "upcoming" }
	]
	property date chosen: new Date()
	property bool adding: false
	readonly property var repeats: ({ once: "Once", daily: "Every day", weekdays: "Weekdays" })

	// the chosen day: events and reminders (all-day first, then by time) with its alarms among them
	readonly property var dayEntries: {
		Events.events;
		Alarms.alarms;
		const events = Events.on(chosen).map(e => ({ kind: e.time ? "reminder" : "event", id: e.id, time: e.time, text: e.text, sub: "", done: !!e.notified }));
		const alarms = Alarms.on(chosen).map(a => ({ kind: "alarm", id: a.id, time: a.time, text: a.label, sub: a.repeat === "once" ? "" : repeats[a.repeat] }));
		return [...events, ...alarms].sort((a, b) => (a.time || "") < (b.time || "") ? -1 : 1);
	}
	// reminders from today on, by when
	readonly property var upcoming: {
		const today = Events.key(new Date());
		return Events.events.filter(e => e.time && e.date >= today).sort((a, b) => a.date + a.time < b.date + b.time ? -1 : 1);
	}

	function dayName(key: string): string {
		const day = new Date(key + "T00:00:00");
		const today = new Date();
		const diff = Math.round((day - new Date(today.getFullYear(), today.getMonth(), today.getDate())) / 86400000);
		return diff === 0 ? "Today" : diff === 1 ? "Tomorrow" : Qt.formatDate(day, diff < 7 ? "dddd" : "ddd d MMM");
	}

	function remove(entry: var): void {
		if (entry.kind === "alarm")
			Alarms.remove(entry.id);
		else
			Events.remove(entry.id);
	}

	onChosenChanged: adding = false
	onViewChanged: adding = false
	spacing: 12

	// one thing on a day: its icon, time, text and a note; ✕ on hover; alarms have their switch
	component Entry: Rectangle {
		id: entry

		required property var modelData
		readonly property bool alarm: modelData.kind === "alarm"

		width: root.width
		height: 44
		radius: 11
		opacity: modelData.done || alarm && modelData.enabled === false ? 0.55 : 1
		color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

		HoverHandler {
			id: hover
		}

		Row {
			x: 14
			anchors.verticalCenter: parent.verticalCenter
			spacing: 10

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g(entry.alarm ? "alarm" : entry.modelData.kind === "reminder" ? "bell" : "calendar")
				filled: entry.modelData.kind !== "event"
				font.pixelSize: 15
				color: entry.modelData.kind === "event" ? Theme.fgMuted : Theme.primary
			}

			Label {
				anchors.verticalCenter: parent.verticalCenter
				visible: !!entry.modelData.time
				text: entry.modelData.time ?? ""
				color: Theme.primary
				font.pixelSize: 13
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				width: Math.min(implicitWidth, root.width - 260)
				text: entry.modelData.text
				elide: Text.ElideRight
				color: Theme.fg
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 14
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				visible: text !== ""
				text: entry.modelData.sub ?? ""
				color: entry.modelData.sub === "Snoozed" ? Theme.primary : Theme.fgMuted
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 12
			}
		}

		Row {
			anchors.right: parent.right
			anchors.rightMargin: 12
			anchors.verticalCenter: parent.verticalCenter
			spacing: 14

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				opacity: hover.hovered ? 1 : 0
				glyph: Icons.g("x")
				font.pixelSize: 14
				color: Theme.fgMuted

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					cursorShape: Qt.PointingHandCursor
					onClicked: root.remove(entry.modelData)
				}
			}

			Toggle {
				visible: entry.alarm && entry.modelData.enabled !== undefined
				anchors.verticalCenter: parent.verticalCenter
				checked: !!entry.modelData.enabled
				onToggled: checked => Alarms.update(entry.modelData.id, { enabled: checked, fired: "" })
			}
		}
	}

	component Heading: Text {
		topPadding: 4
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.pixelSize: 12
		font.weight: Font.DemiBold
		font.capitalization: Font.AllUppercase
		font.letterSpacing: 0.6
	}

	component Empty: Text {
		width: root.width
		topPadding: 6
		bottomPadding: 6
		horizontalAlignment: Text.AlignHCenter
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.pixelSize: 13
	}

	// --- Calendar ---

	MonthGrid {
		visible: root.view === "calendar"
		width: parent.width
		onPicked: day => root.chosen = day
	}

	Item {
		visible: root.view === "calendar"
		width: parent.width
		height: 30

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(root.chosen, "dddd, d MMMM")
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 14
			font.weight: Font.DemiBold
		}

		IconButton {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			size: 30
			radius: 10
			glyph: Icons.g(root.adding ? "x" : "plus")
			glyphSize: 15
			on: root.adding
			filled: false
			idle: Qt.alpha(Theme.surface, 0.8)
			onClicked: {
				root.adding = !root.adding;
				if (root.adding)
					dayComposer.focusField();
			}
		}
	}

	Composer {
		id: dayComposer

		visible: root.view === "calendar" && root.adding
		width: parent.width
		day: root.chosen
		onAdded: root.adding = false
	}

	Repeater {
		model: root.view === "calendar" ? root.dayEntries : []

		delegate: Entry {}
	}

	// --- Reminders & alarms ---

	Composer {
		visible: root.view === "upcoming"
		width: parent.width
		datePicker: true
		day: root.chosen
	}

	Heading {
		visible: root.view === "upcoming"
		text: "Reminders"
	}

	Empty {
		visible: root.view === "upcoming" && root.upcoming.length === 0
		text: "No reminders coming up."
	}

	Repeater {
		model: root.view === "upcoming" ? root.upcoming.map(e => ({ kind: "reminder", id: e.id, time: e.time, text: e.text, sub: root.dayName(e.date), done: !!e.notified })) : []

		delegate: Entry {}
	}

	Heading {
		visible: root.view === "upcoming"
		text: "Alarms"
	}

	Empty {
		visible: root.view === "upcoming" && Alarms.alarms.length === 0
		text: "No alarms."
	}

	Repeater {
		model: root.view === "upcoming" ? Alarms.alarms.map(a => ({ kind: "alarm", id: a.id, time: a.time, text: a.label, enabled: a.enabled, sub: a.snooze ? "Snoozed" : a.repeat === "once" ? (a.date ? root.dayName(a.date) : "Once") : root.repeats[a.repeat] })) : []

		delegate: Entry {}
	}
}
