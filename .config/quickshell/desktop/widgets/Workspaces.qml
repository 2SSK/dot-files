pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs

// This screen's workspaces as dots, no numbers; a click switches. The shown one is a wide accent
// pill, the others muted dots, an urgent one red. Static: square-ish, as polybar's blocks.
Line {
	id: root

	property ShellScreen screen: null // set by the bar

	vertical: Config.vertical
	spacing: 7

	Repeater {
		model: I3.workspaces

		delegate: Item {
			id: ws

			required property I3Workspace modelData

			readonly property bool shown: modelData.active
			readonly property real dot: Math.round(Config.bar.size * 0.3)

			visible: modelData.monitor?.name === root.screen?.name // by name: monitorFor() may return an early copy
			implicitWidth: Config.vertical ? dot : shown ? dot * 3 : dot
			implicitHeight: Config.vertical ? (shown ? dot * 3 : dot) : dot

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
				color: ws.modelData.urgent ? Theme.error : ws.shown ? Theme.primary : hover.containsMouse ? Theme.fg : Qt.alpha(Theme.fgMuted, 0.7)

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
				onClicked: ws.modelData.activate()
			}
		}
	}
}
