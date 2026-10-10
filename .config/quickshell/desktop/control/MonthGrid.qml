pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// A month: its name with ‹ ›, then the days from the start of the week holding the 1st. Today is
// filled with the accent, the chosen day ringed, days of the neighbouring months faint, a dot under
// days with something on (events, reminders, alarms). A click picks a day (picked(day)).
Column {
	id: root

	property date chosen: clock.date
	property int year: chosen.getFullYear()
	property int month: chosen.getMonth() // 0–11
	property real cellHeight: 36
	readonly property int first: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday
	readonly property var days: {
		const start = new Date(year, month, 1);
		start.setDate(1 - (start.getDay() - first + 7) % 7);
		return Array.from({ length: 42 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
	}

	signal picked(date day)

	function shift(months: int): void {
		const next = new Date(year, month + months, 1);
		year = next.getFullYear();
		month = next.getMonth();
	}

	function busy(day: date): bool {
		Events.events;
		Alarms.alarms;
		return Events.has(day) || Alarms.alarms.some(a => a.enabled && a.repeat === "once" && a.date === Qt.formatDate(day, "yyyy-MM-dd"));
	}

	spacing: 10

	SystemClock {
		id: clock

		precision: SystemClock.Hours
	}

	Item {
		width: parent.width
		height: 32

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: Theme.px(16)
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

					width: 30
					height: 30
					radius: 10
					color: arrowHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

					Glyph {
						anchors.centerIn: parent
						glyph: arrow.modelData.glyph
						font.pixelSize: 15
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
		height: grid.implicitHeight + 20
		radius: 16
		color: Qt.alpha(Theme.surface, 0.8)

		Grid {
			id: grid

			readonly property real cell: (parent.width - 20) / 7

			x: 10
			y: 10
			columns: 7
			rowSpacing: 2

			Repeater {
				model: 7

				delegate: Text {
					required property int index

					width: grid.cell
					height: 24
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					text: Qt.locale().dayName((root.first + index) % 7, Locale.ShortFormat).slice(0, 2)
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textLabel
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

					width: grid.cell
					height: root.cellHeight

					Rectangle {
						anchors.centerIn: parent
						width: Math.min(32, root.cellHeight - 4)
						height: width
						radius: width / 2
						color: day.today ? Theme.primary : dayHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"
						border.width: day.picked && !day.today ? 1 : 0
						border.color: Theme.primary
					}

					Text {
						anchors.centerIn: parent
						text: day.modelData.getDate()
						color: day.today ? Theme.primaryText : day.inMonth ? Theme.fg : Qt.alpha(Theme.fgMuted, 0.5)
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textBody
						font.weight: day.today ? Font.Bold : Font.DemiBold // semibold: solid numbers in the grid
						font.features: ({ tnum: 1 })
					}

					Rectangle {
						visible: root.busy(day.modelData)
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 1
						width: 4
						height: 4
						radius: 2
						color: day.today ? Theme.primaryText : Theme.primary
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
							root.picked(day.modelData);
						}
					}
				}
			}
		}
	}
}
