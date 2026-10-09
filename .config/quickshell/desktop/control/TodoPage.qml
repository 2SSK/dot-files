pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.widgets

// Todo: add with Enter, tick off, ✕ removes; the header's button clears the ticked ones.
Column {
	id: root

	readonly property string title: "Todo"
	readonly property var actions: [{ glyph: "\u{EAB2}", on: false, act: () => Todo.clearDone(), show: Todo.items.some(i => i.done) }]

	spacing: 8

	TextField {
		id: field

		width: parent.width
		placeholder: "Add a task and press Enter"
		Component.onCompleted: focusField()
		onAccepted: text => {
			Todo.add(text);
			field.text = "";
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
		model: Todo.items

		delegate: Rectangle {
			id: item

			required property var modelData
			required property int index

			width: root.width
			height: Math.max(48, label.implicitHeight + 24)
			radius: 12
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
					onClicked: Todo.toggle(item.index)
				}
			}

			Text {
				id: label

				anchors.left: box.right
				anchors.leftMargin: 12
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
					onClicked: Todo.remove(item.index)
				}
			}
		}
	}
}
