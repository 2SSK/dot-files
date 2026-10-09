pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.settings
import qs.widgets

// Alarms: each with its time, label and repeat, and a switch; ✕ removes it. Below, a time, a label
// and how often, then Add (or Enter). A ringing one shows a card with Stop and Snooze.
Column {
	id: root

	readonly property string title: "Alarms"
	readonly property var actions: []
	property string repeat: "once"
	readonly property var repeats: ({ once: "Once", daily: "Every day", weekdays: "Weekdays" })

	function add(): void {
		Alarms.add(time.text, label.text, root.repeat);
		if (/^\d{1,2}:\d{2}$/.test(time.text.trim())) {
			time.text = "";
			label.text = "";
		}
	}

	spacing: 10

	Text {
		visible: Alarms.alarms.length === 0
		width: parent.width
		topPadding: 10
		bottomPadding: 10
		horizontalAlignment: Text.AlignHCenter
		text: "No alarms."
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	Repeater {
		model: Alarms.alarms

		delegate: Rectangle {
			id: alarm

			required property var modelData

			width: root.width
			height: 68
			radius: 14
			opacity: modelData.enabled || modelData.snooze ? 1 : 0.55
			color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

			HoverHandler {
				id: hover
			}

			Label {
				id: when

				x: 18
				anchors.verticalCenter: parent.verticalCenter
				text: alarm.modelData.time
				font.pixelSize: 26
				font.weight: Font.Medium
			}

			Column {
				anchors.left: when.right
				anchors.leftMargin: 16
				anchors.verticalCenter: parent.verticalCenter
				spacing: 2

				Text {
					text: alarm.modelData.label
					color: Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 14
					font.weight: Font.Medium
				}

				Text {
					text: alarm.modelData.snooze ? "Snoozed" : root.repeats[alarm.modelData.repeat] ?? ""
					color: alarm.modelData.snooze ? Theme.primary : Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
				}
			}

			Row {
				anchors.right: parent.right
				anchors.rightMargin: 16
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

	// a new one
	Rectangle {
		width: parent.width
		height: adder.implicitHeight + 24
		radius: 14
		color: Qt.alpha(Theme.surface, 0.55)

		Column {
			id: adder

			x: 12
			y: 12
			width: parent.width - 24
			spacing: 10

			Row {
				width: parent.width
				spacing: 8

				TextField {
					id: time

					width: 90
					placeholder: "07:30"
					onAccepted: root.add()
				}

				TextField {
					id: label

					width: parent.width - time.width - add.width - 16
					placeholder: "Label"
					onAccepted: root.add()
				}

				Rectangle {
					id: add

					anchors.verticalCenter: parent.verticalCenter
					width: addLabel.implicitWidth + 28
					height: 34
					radius: 10
					color: addHover.hovered ? Qt.lighter(Theme.primary, 1.1) : Theme.primary

					Text {
						id: addLabel

						anchors.centerIn: parent
						text: "Add"
						color: Theme.onPrimary
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: Font.DemiBold
					}

					HoverHandler {
						id: addHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: root.add()
					}
				}
			}

			Choice {
				options: Object.keys(root.repeats).map(k => ({ value: k, label: root.repeats[k] }))
				value: root.repeat
				onPicked: value => root.repeat = value
			}
		}
	}
}
