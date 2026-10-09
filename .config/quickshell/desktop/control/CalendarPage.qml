pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// A month: ‹ › go back and forward. Today is filled with the accent, the chosen day ringed, days of
// the neighbouring months faint, a dot under days with events. Below: the chosen day's events
// (nothing when there are none) and a small + that opens a line to add one ("09:30" makes it a
// reminder that notifies when due), then the alarms. Weeks start on the locale's first day.
Column {
	id: root

	readonly property string title: "Calendar"
	readonly property var actions: []

	SystemClock {
		id: clock

		precision: SystemClock.Hours
	}

	property int year: clock.date.getFullYear()
	property int month: clock.date.getMonth() // 0–11
	property date chosen: clock.date
	readonly property int first: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday
	// the 42 days on show, from the start of the week holding the 1st
	readonly property var days: {
		const start = new Date(year, month, 1);
		start.setDate(1 - (start.getDay() - first + 7) % 7);
		return Array.from({ length: 42 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
	}
	readonly property var dayEvents: { Events.events; return Events.on(chosen); }
	property bool adding: false

	onChosenChanged: adding = false

	function shift(months: int): void {
		const next = new Date(year, month + months, 1);
		year = next.getFullYear();
		month = next.getMonth();
	}

	spacing: 12

	Item {
		width: parent.width
		height: 32

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
			color: Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 17
			font.weight: Font.DemiBold
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 6

			Repeater {
				model: [{ glyph: Icons.g("chevron-left"), step: -1 }, { glyph: Icons.g("chevron-right"), step: 1 }]

				delegate: Rectangle {
					id: arrow

					required property var modelData

					width: 32
					height: 32
					radius: 10
					color: arrowHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

					Glyph {
						anchors.centerIn: parent
						glyph: arrow.modelData.glyph
						font.pixelSize: 16
					}

					HoverHandler {
						id: arrowHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: root.shift(arrow.modelData.step)
					}
				}
			}
		}
	}

	Rectangle {
		width: parent.width
		height: grid.implicitHeight + 24
		radius: 16
		color: Qt.alpha(Theme.surface, 0.8)

		Grid {
			id: grid

			readonly property real cell: (parent.width - 24) / 7

			x: 12
			y: 12
			columns: 7
			rowSpacing: 2

			// weekday names
			Repeater {
				model: 7

				delegate: Text {
					required property int index

					width: grid.cell
					height: 26
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					text: Qt.locale().dayName((root.first + index) % 7, Locale.ShortFormat).slice(0, 2)
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.DemiBold
				}
			}

			Repeater {
				model: root.days

				delegate: Item {
					id: day

					required property var modelData
					readonly property bool today: modelData.toDateString() === clock.date.toDateString()
					readonly property bool picked: modelData.toDateString() === root.chosen.toDateString()
					readonly property bool inMonth: modelData.getMonth() === root.month
					readonly property bool busy: { Events.events; return Events.has(modelData); }

					width: grid.cell
					height: 36

					Rectangle {
						anchors.centerIn: parent
						width: 32
						height: 32
						radius: 16
						color: day.today ? Theme.primary : dayHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"
						border.width: day.picked && !day.today ? 1 : 0
						border.color: Theme.primary
					}

					Text {
						anchors.centerIn: parent
						text: day.modelData.getDate()
						color: day.today ? Theme.onPrimary : day.inMonth ? Theme.fg : Qt.alpha(Theme.fgMuted, 0.5)
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: day.today ? Font.Bold : Font.Normal
						font.features: ({ tnum: 1 })
					}

					// has events
					Rectangle {
						visible: day.busy
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 1
						width: 4
						height: 4
						radius: 2
						color: day.today ? Theme.onPrimary : Theme.primary
					}

					HoverHandler {
						id: dayHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.chosen = day.modelData;
							if (!day.inMonth)
								root.shift(day.modelData < new Date(root.year, root.month, 1) ? -1 : 1);
						}
					}
				}
			}
		}
	}

	// the chosen day, and + to add to it
	Item {
		width: parent.width
		height: 30

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(root.chosen, "dddd, d MMMM")
			color: Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 14
			font.weight: Font.DemiBold
		}

		Rectangle {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			width: 30
			height: 30
			radius: 10
			color: root.adding ? Theme.primary : addHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

			Glyph {
				anchors.centerIn: parent
				glyph: Icons.g(root.adding ? "x" : "plus")
				font.pixelSize: 15
				color: root.adding ? Theme.onPrimary : Theme.fg
			}

			HoverHandler {
				id: addHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					root.adding = !root.adding;
					if (root.adding)
						what.focusField();
				}
			}
		}
	}

	Repeater {
		model: root.dayEvents

		delegate: Rectangle {
			id: event

			required property var modelData

			width: root.width
			height: 44
			radius: 11
			color: eventHover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

			HoverHandler {
				id: eventHover
			}

			Row {
				x: 14
				anchors.verticalCenter: parent.verticalCenter
				spacing: 10

				Glyph {
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g(event.modelData.time ? "bell" : "calendar")
					filled: !!event.modelData.time && !event.modelData.notified
					font.pixelSize: 15
					color: event.modelData.time ? Theme.primary : Theme.fgMuted
				}

				Label {
					anchors.verticalCenter: parent.verticalCenter
					visible: !!event.modelData.time
					text: event.modelData.time
					color: Theme.primary
					font.pixelSize: 13
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					width: root.width - 140
					text: event.modelData.text
					elide: Text.ElideRight
					color: Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 14
				}
			}

			Glyph {
				anchors.right: parent.right
				anchors.rightMargin: 14
				anchors.verticalCenter: parent.verticalCenter
				opacity: eventHover.hovered ? 1 : 0
				glyph: Icons.g("x")
				font.pixelSize: 14
				color: Theme.fgMuted

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					cursorShape: Qt.PointingHandCursor
					onClicked: Events.remove(event.modelData.id)
				}
			}
		}
	}

	// add one: an optional time, then the text
	Row {
		visible: root.adding
		width: parent.width
		spacing: 8

		TextField {
			id: time

			width: 86
			placeholder: "time"
		}

		TextField {
			id: what

			width: parent.width - time.width - 8
			placeholder: "What, and Enter"
			onAccepted: value => {
				Events.add(root.chosen, time.text, value);
				what.text = "";
				time.text = "";
				root.adding = false;
			}
		}
	}

	AlarmList {
		width: parent.width
		topPadding: 10
	}
}
