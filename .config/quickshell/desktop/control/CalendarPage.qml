pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.widgets

// A month: arrows go back and forward, Today returns; today is filled with the accent, days of the
// neighbouring months are faint. Weeks start on the locale's first day.
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
	readonly property int first: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday
	// the 42 days on show, from the start of the week holding the 1st
	readonly property var days: {
		const start = new Date(year, month, 1);
		start.setDate(1 - (start.getDay() - first + 7) % 7);
		return Array.from({ length: 42 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
	}

	function shift(months: int): void {
		const next = new Date(year, month + months, 1);
		year = next.getFullYear();
		month = next.getMonth();
	}

	spacing: 14

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
				model: [
					{ glyph: Icons.g("caret-left"), act: () => root.shift(-1) },
					{ text: "Today", act: () => { root.year = clock.date.getFullYear(); root.month = clock.date.getMonth(); } },
					{ glyph: Icons.g("caret-right"), act: () => root.shift(1) }
				]

				delegate: Rectangle {
					id: button

					required property var modelData

					width: modelData.text ? label.implicitWidth + 22 : 32
					height: 32
					radius: 10
					color: buttonHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

					Text {
						id: label

						anchors.centerIn: parent
						text: button.modelData.text ?? button.modelData.glyph
						color: Theme.fg
						font.family: button.modelData.text ? Theme.fontSans : Icons.light
						font.pixelSize: 13
						font.weight: Font.Medium
					}

					HoverHandler {
						id: buttonHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: button.modelData.act()
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

			x: 12
			y: 12
			columns: 7
			columnSpacing: 0
			rowSpacing: 4

			readonly property real cell: (parent.width - 24) / 7

			// weekday names
			Repeater {
				model: 7

				delegate: Text {
					required property int index

					width: grid.cell
					height: 28
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
					readonly property bool inMonth: modelData.getMonth() === root.month

					width: grid.cell
					height: 38

					Rectangle {
						anchors.centerIn: parent
						width: 34
						height: 34
						radius: 17
						color: day.today ? Theme.primary : "transparent"
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
				}
			}
		}
	}

	Text {
		text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}
}
