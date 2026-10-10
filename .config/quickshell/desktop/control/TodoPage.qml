pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.widgets

// Todo: pick a priority and add with Enter. Open tasks come first, high to low, then done ones;
// drag a task (anywhere on it) to reorder it (among another priority's tasks it takes theirs), a
// click on its H / M / L changes it, the circle ticks it off, ✕ removes it. The header's button
// clears the done ones.
Item {
	id: root

	readonly property string title: "Todo"
	readonly property var actions: [{ glyph: Icons.g("check"), on: false, act: () => Todo.clearDone(), show: Todo.items.some(i => i.done) }]
	readonly property var priorities: ({
			high: { letter: "H", colour: Theme.error },
			medium: { letter: "M", colour: Theme.primary },
			low: { letter: "L", colour: Theme.fgMuted }
		})
	property string priority: "medium" // for the next task
	// a drag: the task, the pointer (in this page) and where it would land in the sorted list
	property string dragId: ""
	property real dragY: 0
	property int dropIndex: -1

	function landing(y: real): int {
		for (let i = 0; i < rows.count; i++) {
			const row = rows.itemAt(i);
			if (y < row.mapToItem(root, 0, 0).y + row.height / 2)
				return i;
		}
		return rows.count;
	}

	implicitHeight: list.implicitHeight

	Column {
		id: list

		width: parent.width
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
							font.hintingPreference: Theme.hinting
							font.pixelSize: Theme.textBody
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
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: Theme.textBody
		}

		Repeater {
			id: rows

			model: Todo.sorted

			delegate: Rectangle {
				id: item

				required property var modelData
				required property int index
				readonly property var level: root.priorities[modelData.priority]
				readonly property bool dragged: root.dragId === modelData.id

				width: root.width
				height: Math.max(48, label.implicitHeight + 24)
				radius: 12
				opacity: dragged ? 0.35 : modelData.done ? 0.6 : 1
				color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

				HoverHandler {
					id: hover
				}

				// where the dragged task would land: above this one
				Rectangle {
					visible: root.dragId !== "" && root.dropIndex === item.index && !item.dragged
					y: -5
					width: parent.width
					height: 2
					radius: 1
					color: Theme.primary
				}

				// the grip, a hint that the row drags
				Glyph {
					id: handle

					x: 4
					anchors.verticalCenter: parent.verticalCenter
					width: 14
					opacity: hover.hovered || item.dragged ? 0.8 : 0
					glyph: Icons.g("grip-vertical")
					font.pixelSize: 14
					color: Theme.fgMuted
				}

				// the whole row drags: a press that moves more than a few pixels starts it (a plain click
				// still reaches the circle, the H / M / L and ✕ above this)
				MouseArea {
					property real pressY: 0

					anchors.fill: parent
					preventStealing: true // not a scroll of the panel
					cursorShape: root.dragId ? Qt.ClosedHandCursor : Qt.OpenHandCursor
					onPressed: event => pressY = event.y
					onPositionChanged: event => {
						if (!pressed)
							return;
						if (!root.dragId && Math.abs(event.y - pressY) < 6)
							return;
						root.dragId = item.modelData.id;
						root.dragY = mapToItem(root, event.x, event.y).y;
						root.dropIndex = root.landing(root.dragY);
					}
					onReleased: {
						if (root.dragId === item.modelData.id && root.dropIndex !== item.index && root.dropIndex !== item.index + 1)
							Todo.move(item.modelData.id, root.dropIndex > item.index ? root.dropIndex - 1 : root.dropIndex);
						root.dragId = "";
						root.dropIndex = -1;
					}
				}

				Rectangle {
					id: box

					x: 22
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
						glyph: Icons.g("check")
						font.pixelSize: 12
						color: Theme.primaryText
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
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textLabel
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
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: Theme.textBody
				}

				Glyph {
					id: remove

					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.verticalCenter: parent.verticalCenter
					opacity: hover.hovered ? 1 : 0
					glyph: Icons.g("x")
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

	// the dragged task, under the pointer; and the landing line after the last task
	Rectangle {
		visible: root.dragId !== "" && root.dropIndex === rows.count
		x: 0
		y: rows.count ? rows.itemAt(rows.count - 1).mapToItem(root, 0, 0).y + rows.itemAt(rows.count - 1).height + 3 : 0
		width: root.width
		height: 2
		radius: 1
		color: Theme.primary
	}

	Rectangle {
		visible: root.dragId !== ""
		z: 10
		x: 24
		y: root.dragY - height / 2
		width: root.width - 48
		height: 40
		radius: 12
		color: Theme.primary

		Text {
			anchors.left: parent.left
			anchors.leftMargin: 16
			anchors.right: parent.right
			anchors.rightMargin: 16
			anchors.verticalCenter: parent.verticalCenter
			text: Todo.items.find(item => item.id === root.dragId)?.text ?? ""
			elide: Text.ElideRight
			color: Theme.primaryText
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: Theme.textBody
			font.weight: Font.Medium
		}
	}
}
