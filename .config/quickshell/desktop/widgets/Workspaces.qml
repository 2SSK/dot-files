pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services

// This screen's workspaces as dots, no numbers: the ones with windows, and the one you're on (i3
// and sway drop a workspace once it's empty and left). The one showing on this screen is a wide
// pill, in the accent where the focus is (dimmer on another monitor); an urgent one is red; a click
// switches. Read from WindowManager, which follows i3's own events.
Line {
	id: root

	property ShellScreen screen: null // set by the bar
	readonly property var here: WindowManager.workspaces.filter(ws => ws.output === screen?.name)

	vertical: Config.vertical
	spacing: 7

	Repeater {
		model: root.here

		delegate: Item {
			id: slot

			required property var modelData

			readonly property var workspace: modelData
			readonly property bool shown: workspace.visible
			readonly property real dot: Math.round(Config.bar.size * 0.38)

			implicitWidth: Config.vertical ? dot : shown ? dot * 2.6 : dot
			implicitHeight: Config.vertical ? (shown ? dot * 2.6 : dot) : dot

			Behavior on implicitWidth {
				NumberAnimation {
					duration: 260
					easing.type: Easing.OutCubic
				}
			}

			Behavior on implicitHeight {
				NumberAnimation {
					duration: 260
					easing.type: Easing.OutCubic
				}
			}

			Rectangle {
				anchors.fill: parent
				radius: Config.island ? Math.min(width, height) / 2 : 2
				color: slot.workspace.urgent ? Theme.error : slot.shown ? (slot.workspace.focused ? Theme.primary : Qt.alpha(Theme.primary, 0.55)) : hover.containsMouse ? Theme.fg : Qt.alpha(Theme.fg, 0.6)

				Behavior on color {
					ColorAnimation {
						duration: 180
					}
				}
			}

			MouseArea {
				id: hover

				anchors.fill: parent
				anchors.margins: -4
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: WindowManager.switchTo(slot.workspace.num)
			}
		}
	}
}
