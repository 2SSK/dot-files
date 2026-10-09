pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3

// Workspace pills of one screen: filled = focused, outlined = the others, red = urgent. A click
// switches to the workspace. Quickshell.I3 talks to i3 (and to sway, which speaks the same IPC).
Row {
	id: root

	required property ShellScreen screen

	spacing: 6

	Repeater {
		model: I3.workspaces

		delegate: Rectangle {
			id: pill

			required property I3Workspace modelData

			visible: pill.modelData.monitor === I3.monitorFor(root.screen)
			implicitWidth: Math.max(24, label.implicitWidth + 16)
			implicitHeight: 22
			radius: height / 2
			color: pill.modelData.focused ? Theme.primary : "transparent"
			border.width: pill.modelData.focused ? 0 : 1
			border.color: pill.modelData.urgent ? Theme.error : Theme.border

			Behavior on color {
				ColorAnimation {
					duration: 150
				}
			}

			Text {
				id: label

				anchors.centerIn: parent
				text: pill.modelData.name
				color: pill.modelData.focused ? Theme.onPrimary : pill.modelData.urgent ? Theme.error : Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 12
				font.weight: Font.Medium
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: pill.modelData.activate()
			}
		}
	}
}
