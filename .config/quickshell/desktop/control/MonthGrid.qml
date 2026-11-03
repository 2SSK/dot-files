pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// A month from the start of the week holding the 1st: today filled, the chosen day ringed, a dot
// under days with something on, weekends softer, the ISO week down the side. A click picks a day;
// Today comes back to it.
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

	function today(): void {
		const now = new Date();
		year = now.getFullYear();
		month = now.getMonth();
		chosen = now;
		picked(now);
	}

	// ISO 8601: the week of the year its Thursday falls in
	function isoWeek(day: date): int {
		const d = new Date(Date.UTC(day.getFullYear(), day.getMonth(), day.getDate()));
		d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
		return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7);
	}

	function busy(day: date): bool {
		Events.events;
		Alarms.alarms;
		return Events.has(day) || Alarms.alarms.some(a => a.enabled && a.repeat === "once" && a.date === Qt.formatDate(day, "yyyy-MM-dd"));
	}

	spacing: 12

	SystemClock {
		id: clock

		precision: SystemClock.Hours
	}

	Item {
		width: parent.width
		height: 32

		UiText {
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
			font.family: Theme.fontHeading
			font.pixelSize: Theme.px(16)
			font.weight: Font.DemiBold
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 6

			// back to today, from another month or day
			Rectangle {
				visible: root.year !== clock.date.getFullYear() || root.month !== clock.date.getMonth() || root.chosen.toDateString() !== clock.date.toDateString()
				width: todayLabel.implicitWidth + 22
				height: 30
				radius: Theme.radiusCard
				color: todayHover.hovered ? Qt.alpha(Theme.primary, 0.25) : Qt.alpha(Theme.primary, 0.15)

				UiText {
					id: todayLabel

					anchors.centerIn: parent
					text: "Today"
					color: Theme.primary
					font.pixelSize: Theme.textLabel
					font.weight: Font.DemiBold
				}

				HoverHandler {
					id: todayHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.today()
				}
			}

			Repeater {
				model: [{ glyph: Icons.g("chevron-left"), step: -1 }, { glyph: Icons.g("chevron-right"), step: 1 }]

				delegate: Rectangle {
					id: arrow

					required property var modelData

					width: 30
					height: 30
					radius: Theme.radiusCard
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
		radius: Theme.radiusCard
		color: Qt.alpha(Theme.surface, 0.8)

		Column {
			id: grid

			readonly property real week: 30 // the week numbers' column
			readonly property real cell: (parent.width - 20 - week) / 7

			x: 10
			y: 10
			spacing: 2

			Row {
				Text {
					width: grid.week
					height: 24
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					text: "Wk"
					color: Qt.alpha(Theme.fgMuted, 0.6)
					font.family: Theme.fontHeading
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textCaption
				}

				Repeater {
					model: 7

					delegate: Text {
						required property int index
						readonly property int weekday: (root.first + index) % 7

						width: grid.cell
						height: 24
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						text: Qt.locale().dayName(weekday, Locale.ShortFormat).slice(0, 2)
						color: weekday === 0 || weekday === 6 ? Qt.alpha(Theme.fgMuted, 0.65) : Theme.fgMuted
						font.family: Theme.fontHeading
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textLabel
						font.weight: Font.DemiBold
					}
				}
			}

			Repeater {
				model: 6

				delegate: Row {
					id: week

					required property int index
					readonly property var days: root.days.slice(index * 7, index * 7 + 7)

					Text {
						width: grid.week
						height: root.cellHeight
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						// the week's Thursday decides its number
						text: root.isoWeek(week.days[(4 - root.first + 7) % 7])
						color: Qt.alpha(Theme.fgMuted, 0.6)
						font.family: Theme.fontMono
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textCaption
					}

					Repeater {
						model: week.days

						delegate: Item {
							id: day

							required property var modelData
							readonly property bool today: modelData.toDateString() === clock.date.toDateString()
							readonly property bool picked: modelData.toDateString() === root.chosen.toDateString()
							readonly property bool inMonth: modelData.getMonth() === root.month
							readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6

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

							UiText {
								anchors.centerIn: parent
								text: day.modelData.getDate()
								color: day.today ? Theme.primaryText : !day.inMonth ? Qt.alpha(Theme.fgMuted, 0.5) : day.weekend ? Theme.fgMuted : Theme.fg
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
	}
}
