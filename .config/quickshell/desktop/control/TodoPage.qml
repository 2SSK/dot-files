pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.widgets

// Todo: pick a priority and add with Enter. Open tasks come first, high to low, then done ones;
// a click on a task's H / M / L changes it, the circle ticks it off, ✕ removes it. The header's
// button clears the done ones.
Column {
	id: root

	readonly property string title: "Todo"
	readonly property var actions: [{ glyph: "\u{EAB2}", on: false, act: () => Todo.clearDone(), show: Todo.items.some(i => i.done) }]
	readonly property var priorities: ({
			high: { letter: "H", colour: Theme.error },
			medium: { letter: "M", colour: Theme.primary },
			low: { letter: "L", colour: Theme.fgMuted }
		})
	property string priority: "medium" // for the next task

	spacing: 8

	Row {
		width: parent.width
		spacing: 8

		TextField {
			id: field

			width: parent.width - picker.width - 8
			placeholder: "Add a task and press Enter"
			Component.onCompleted: focusField()
			onAccepted: text => {
				Todo.add(text, root.priority);
				field.text = "";
			}
		}

		// the next task's priority
		Row {
			id: picker

			anchors.verticalCenter: parent.verticalCenter
			spacing: 4

			Repeater {
				model: ["high", "medium", "low"]

				delegate: Rectangle {
					id: choice

					required property string modelData
					readonly property bool on: root.priority === modelData
					readonly property color colour: root.priorities[modelData].colour

					width: 34
					height: 34
					radius: 10
					color: on ? colour : Qt.alpha(colour, 0.14)

					Text {
						anchors.centerIn: parent
						text: root.priorities[choice.modelData].letter
						color: choice.on ? Theme.bg : choice.colour
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: Font.Bold
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.priority = choice.modelData;
							field.focusField();
						}
					}
				}
			}
		}
	}

	Text {
		visible: Todo.items.length === 0
		width: parent.width
		topPadding: 24
		horizontalAlignment: Text.AlignHCenter
		text: "Nothing to do."
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	Repeater {
		model: Todo.sorted

		delegate: Rectangle {
			id: item

			required property var modelData
			readonly property var level: root.priorities[modelData.priority]

			width: root.width
			height: Math.max(48, label.implicitHeight + 24)
			radius: 12
			opacity: modelData.done ? 0.6 : 1
			color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

			HoverHandler {
				id: hover
			}

			Rectangle {
				id: box

				x: 14
				anchors.verticalCenter: parent.verticalCenter
				width: 20
				height: 20
				radius: 10
				color: item.modelData.done ? Theme.primary : "transparent"
				border.width: item.modelData.done ? 0 : 2
				border.color: Theme.fgMuted

				Glyph {
					anchors.centerIn: parent
					visible: item.modelData.done
					text: "\u{EAB2}"
					font.pixelSize: 12
					color: Theme.onPrimary
				}

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					cursorShape: Qt.PointingHandCursor
					onClicked: Todo.toggle(item.modelData.id)
				}
			}

			// the priority: a click changes it
			Rectangle {
				id: badge

				anchors.left: box.right
				anchors.leftMargin: 12
				anchors.verticalCenter: parent.verticalCenter
				width: 24
				height: 22
				radius: 7
				color: Qt.alpha(item.level.colour, 0.16)

				Text {
					anchors.centerIn: parent
					text: item.level.letter
					color: item.level.colour
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.Bold
				}

				MouseArea {
					anchors.fill: parent
					anchors.margins: -4
					cursorShape: Qt.PointingHandCursor
					onClicked: Todo.cyclePriority(item.modelData.id)
				}
			}

			Text {
				id: label

				anchors.left: badge.right
				anchors.leftMargin: 10
				anchors.right: remove.left
				anchors.rightMargin: 8
				anchors.verticalCenter: parent.verticalCenter
				text: item.modelData.text
				wrapMode: Text.Wrap
				font.strikeout: item.modelData.done
				color: item.modelData.done ? Theme.fgMuted : Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 14
			}

			Glyph {
				id: remove

				anchors.right: parent.right
				anchors.rightMargin: 14
				anchors.verticalCenter: parent.verticalCenter
				opacity: hover.hovered ? 1 : 0
				text: "\u{EA76}"
				font.pixelSize: 14
				font.weight: Font.Normal
				color: Theme.fgMuted

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					cursorShape: Qt.PointingHandCursor
					onClicked: Todo.remove(item.modelData.id)
				}
			}
		}
	}
}
