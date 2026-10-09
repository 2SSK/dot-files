pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The power menu: arrows or the mouse pick, Enter or a click runs it (with confirm on, a second
// press), 1–5 jump to an action, Escape closes.
Row {
	spacing: 10

	Repeater {
		model: Panel.actions

		delegate: Rectangle {
			id: action

			required property var modelData
			required property int index

			readonly property bool selected: Panel.selected === index
			readonly property bool armed: Panel.armed === index

			width: 92
			height: 92
			radius: 18
			color: armed ? Qt.alpha(Theme.error, 0.22) : selected ? Qt.alpha(Theme.primary, 0.16) : "transparent"
			border.width: selected ? 1 : 0
			border.color: armed ? Theme.error : Theme.primary

			Behavior on color {
				ColorAnimation {
					duration: 150
				}
			}

			Column {
				anchors.centerIn: parent
				spacing: 8

				Glyph {
					anchors.horizontalCenter: parent.horizontalCenter
					text: action.modelData.glyph
					font.pixelSize: 28
					color: action.armed ? Theme.error : action.selected ? Theme.primary : Theme.fg
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: action.armed ? "Again?" : action.modelData.label
					color: action.armed ? Theme.error : action.selected ? Theme.fg : Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.Medium
				}
			}

			Text {
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: 8
				text: action.index + 1
				color: Theme.fgMuted
				opacity: 0.6
				font.family: Theme.fontMono
				font.pixelSize: 10
			}

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onEntered: if (Panel.selected !== action.index) Panel.move(action.index - Panel.selected)
				onClicked: Panel.activate(action.index)
			}
		}
	}
}
