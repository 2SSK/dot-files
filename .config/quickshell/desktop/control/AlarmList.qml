pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.settings
import qs.widgets

// Alarms, under the calendar: each with its time, label, repeat and a switch; ✕ removes it. The
// small + opens a line: a time, a label, how often (a click steps it), then Enter. A ringing one
// shows a card under the bar with Snooze (again in 5 minutes) and Stop.
Column {
	id: root

	readonly property var repeats: ({ once: "Once", daily: "Every day", weekdays: "Weekdays" })
	property string repeat: "once"
	property bool adding: false

	function add(): void {
		if (!/^\d{1,2}:\d{2}$/.test(time.text.trim()))
			return time.focusField();
		Alarms.add(time.text, label.text, root.repeat);
		time.text = "";
		label.text = "";
		adding = false;
	}

	spacing: 8

	Item {
		width: parent.width
		height: 30

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: "Alarms"
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
						time.focusField();
				}
			}
		}
	}

	Repeater {
		model: Alarms.alarms

		delegate: Rectangle {
			id: alarm

			required property var modelData

			width: root.width
			height: 48
			radius: 11
			opacity: modelData.enabled || modelData.snooze ? 1 : 0.55
			color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

			HoverHandler {
				id: hover
			}

			Row {
				x: 14
				anchors.verticalCenter: parent.verticalCenter
				spacing: 12

				Label {
					anchors.verticalCenter: parent.verticalCenter
					text: alarm.modelData.time
					font.pixelSize: 18
					font.weight: Font.Medium
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: alarm.modelData.label
					color: Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 14
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: alarm.modelData.snooze ? "Snoozed" : root.repeats[alarm.modelData.repeat] ?? ""
					color: alarm.modelData.snooze ? Theme.primary : Theme.fgMuted
					font.family: Theme.fontSans
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
						onClicked: Alarms.remove(alarm.modelData.id)
					}
				}

				Toggle {
					anchors.verticalCenter: parent.verticalCenter
					checked: alarm.modelData.enabled
					onToggled: checked => Alarms.update(alarm.modelData.id, { enabled: checked, fired: "" })
				}
			}
		}
	}

	// a new one: time, label, how often
	Row {
		visible: root.adding
		width: parent.width
		spacing: 8

		TextField {
			id: time

			width: 86
			placeholder: "07:30"
			onAccepted: root.add()
		}

		TextField {
			id: label

			width: parent.width - time.width - often.width - 16
			placeholder: "Label, and Enter"
			onAccepted: root.add()
		}

		Rectangle {
			id: often

			anchors.verticalCenter: parent.verticalCenter
			width: oftenLabel.implicitWidth + 24
			height: 34
			radius: 10
			color: oftenHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)
			border.width: 1
			border.color: Qt.alpha(Theme.border, 0.7)

			Text {
				id: oftenLabel

				anchors.centerIn: parent
				text: root.repeats[root.repeat]
				color: Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 13
			}

			HoverHandler {
				id: oftenHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					const keys = Object.keys(root.repeats);
					root.repeat = keys[(keys.indexOf(root.repeat) + 1) % keys.length];
				}
			}
		}
	}
}
