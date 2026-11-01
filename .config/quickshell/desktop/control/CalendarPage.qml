pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.settings
import qs.widgets

// The calendar in two views: a month with the chosen day's events, reminders and alarms below and
// the week ahead after them (the day as a list, or as a timeline in hours), and the reminders coming
// up with every alarm. Each has a line to add one; an event or reminder is edited where it is (the
// pencil, or a double-click). Repeating events show on every day they happen.
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
	property string editing: "" // the id of the event being edited, if any
	property string dayView: "list" // the chosen day as a list or a timeline
	readonly property var repeats: ({ once: "Once", daily: "Every day", weekdays: "Weekdays" })

	readonly property var dayEntries: {
		Events.events;
		Alarms.alarms;
		const events = Events.on(chosen).map(e => entryOf(e, e.repeat ? Events.repeats[e.repeat] : ""));
		const alarms = Alarms.on(chosen).map(a => ({ kind: "alarm", id: a.id, time: a.time, text: a.label, sub: a.repeat === "once" ? "" : repeats[a.repeat] }));
		return [...events, ...alarms].sort((a, b) => (a.time || "") < (b.time || "") ? -1 : 1);
	}
	// the next seven days after today, whatever the chosen day: events and reminders, by day and time
	readonly property var weekAhead: {
		const today = new Date();
		const from = Events.key(new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1));
		const to = Events.key(new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7));
		return Events.between(Events.dateOf(from), Events.dateOf(to)).map(e => entryOf(e, dayName(e.date)));
	}
	// the next month's reminders (a repeating one at each time it comes)
	readonly property var upcoming: {
		const today = new Date();
		return Events.between(today, new Date(today.getFullYear(), today.getMonth() + 1, today.getDate())).filter(e => e.time);
	}

	// an occurrence as an entry in a list
	function entryOf(e: var, sub: string): var {
		return { kind: e.time ? "reminder" : "event", id: e.id, time: e.time, end: e.end ?? "", repeat: e.repeat ?? "", text: e.text, sub, done: e.done };
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

	onChosenChanged: {
		adding = false;
		editing = "";
	}
	onViewChanged: {
		adding = false;
		editing = "";
	}
	spacing: 12

	component Entry: Rectangle {
		id: entry

		required property var modelData
		readonly property bool alarm: modelData.kind === "alarm"
		readonly property bool editing: !alarm && root.editing === modelData.id

		property string repeat: ""

		function save(): void {
			Events.update(modelData.id, editTime.text, editText.text, repeat);
			root.editing = "";
		}

		width: root.width
		height: 44
		radius: 11
		opacity: !editing && (modelData.done || alarm && modelData.enabled === false) ? 0.55 : 1
		color: editing ? Qt.alpha(Theme.primary, 0.12) : hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)
		border.width: editing ? 1 : 0
		border.color: Qt.alpha(Theme.primary, 0.5)

		HoverHandler {
			id: hover
		}

		MouseArea {
			anchors.fill: parent
			enabled: !entry.alarm && !entry.editing
			onDoubleClicked: root.editing = entry.modelData.id
		}

		// the editor: time (empty for an all-day event) and text; Enter saves, Escape leaves it as it was
		Row {
			visible: entry.editing
			x: 8
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width - 16
			spacing: 8

			TextField {
				id: editTime

				width: 116
				placeholder: "hh:mm-hh:mm"
				onVisibleChanged: {
					if (visible) {
						text = (entry.modelData.time ?? "") + (entry.modelData.end ? "-" + entry.modelData.end : "");
						entry.repeat = entry.modelData.repeat ?? "";
					}
				}
				onAccepted: entry.save()
				onKeyPressed: event => {
					if (event.key === Qt.Key_Escape) {
						root.editing = "";
						event.accepted = true;
					}
				}
			}

			TextField {
				id: editText

				width: parent.width - editTime.width - repeatChip.width - saveButton.width - 24
				placeholder: "What's on"
				onVisibleChanged: {
					if (visible) {
						text = entry.modelData.text;
						focusField();
					}
				}
				onAccepted: entry.save()
				onKeyPressed: event => {
					if (event.key === Qt.Key_Escape) {
						root.editing = "";
						event.accepted = true;
					}
				}
			}

			Chip {
				id: repeatChip

				anchors.verticalCenter: parent.verticalCenter
				label: Events.repeats[entry.repeat]
				on: entry.repeat !== ""
				onClicked: {
					const keys = Object.keys(Events.repeats);
					entry.repeat = keys[(keys.indexOf(entry.repeat) + 1) % keys.length];
				}
			}

			SmallButton {
				id: saveButton

				anchors.verticalCenter: parent.verticalCenter
				accent: true
				text: "Save"
				onClicked: entry.save()
			}
		}

		Row {
			visible: !entry.editing
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
				text: (entry.modelData.time ?? "") + (entry.modelData.end ? "–" + entry.modelData.end : "")
				color: Theme.primary
				font.pixelSize: Theme.textLabel
			}

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				width: Math.min(implicitWidth, root.width - 260)
				text: entry.modelData.text
				elide: Text.ElideRight
			}

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				visible: text !== ""
				text: entry.modelData.sub ?? ""
				color: entry.modelData.sub === "Snoozed" ? Theme.primary : Theme.fgMuted
				font.pixelSize: Theme.textLabel
			}
		}

		Row {
			visible: !entry.editing
			anchors.right: parent.right
			anchors.rightMargin: 12
			anchors.verticalCenter: parent.verticalCenter
			spacing: 14

			Glyph {
				visible: !entry.alarm
				anchors.verticalCenter: parent.verticalCenter
				opacity: hover.hovered ? 1 : 0
				glyph: Icons.g("pencil")
				font.pixelSize: 14
				color: Theme.fgMuted

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					cursorShape: Qt.PointingHandCursor
					onClicked: root.editing = entry.modelData.id
				}
			}

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
		font.family: Theme.fontHeading
		font.hintingPreference: Theme.hinting
		font.pixelSize: Theme.textLabel
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
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textBody
	}

	MonthGrid {
		visible: root.view === "calendar"
		width: parent.width
		onPicked: day => root.chosen = day
	}

	Item {
		visible: root.view === "calendar"
		width: parent.width
		height: 30

		UiText {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(root.chosen, "dddd, d MMMM")
			font.family: Theme.fontHeading
			font.weight: Font.DemiBold
		}

		Row {
			anchors.right: addButton.left
			anchors.rightMargin: 8
			anchors.verticalCenter: parent.verticalCenter
			spacing: 4

			Repeater {
				model: [{ key: "list", glyph: "list" }, { key: "timeline", glyph: "clock-hour-4" }]

				delegate: IconButton {
					required property var modelData

					size: 30
					radius: 10
					glyph: Icons.g(modelData.glyph)
					glyphSize: 15
					on: root.dayView === modelData.key
					idle: Qt.alpha(Theme.surface, 0.8)
					onClicked: root.dayView = modelData.key
				}
			}
		}

		IconButton {
			id: addButton

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

	// the list: everything on the day; the timeline: the all-day ones here, the timed ones below in hours
	Repeater {
		model: root.view !== "calendar" ? [] : root.dayView === "list" ? root.dayEntries : root.dayEntries.filter(e => !e.time)

		delegate: Entry {}
	}

	Empty {
		visible: root.view === "calendar" && root.dayView === "list" && root.dayEntries.length === 0 && !root.adding
		text: "Nothing on this day."
	}

	DayTimeline {
		visible: root.view === "calendar" && root.dayView === "timeline"
		width: parent.width
		height: implicitHeight
		day: root.chosen
		entries: root.dayEntries.filter(e => e.kind !== "alarm")
		onEmptyClicked: hhmm => {
			root.adding = true;
			dayComposer.startAt(hhmm);
		}
		// edited in the list, where the editor is
		onEntryClicked: entry => {
			root.dayView = "list";
			root.editing = entry.id;
		}
	}

	Heading {
		visible: root.view === "calendar" && root.weekAhead.length > 0
		topPadding: 10
		text: "Coming up"
	}

	Repeater {
		model: root.view === "calendar" ? root.weekAhead : []

		delegate: Entry {}
	}

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
		model: root.view === "upcoming" ? root.upcoming.map(e => root.entryOf(e, root.dayName(e.date))) : []

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
