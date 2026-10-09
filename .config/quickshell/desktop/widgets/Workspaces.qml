pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs

// This screen's workspaces; a click switches. Island: the shown one is a wide accent pill. Static:
// it gets a raised background and an accent line on the inner edge, as polybar had.
Line {
	id: root

	property ShellScreen screen: null // set by the bar

	vertical: Config.vertical
	spacing: Config.island ? 4 : 0

	Repeater {
		model: I3.workspaces

		delegate: Item {
			id: ws

			required property I3Workspace modelData

			readonly property bool shown: modelData.active
			readonly property real base: Math.round(Config.bar.size * 0.62)
			readonly property real along: Config.island ? (shown ? base * 2 : base) : Math.max(Config.bar.size, label.implicitWidth + 18)
			readonly property real across: Config.island ? base : Config.bar.size

			visible: modelData.monitor?.name === root.screen?.name // by name: monitorFor() may return an early copy
			implicitWidth: Config.vertical ? across : along
			implicitHeight: Config.vertical ? along : across

			Behavior on implicitWidth {
				NumberAnimation {
					duration: 220
					easing.type: Easing.OutCubic
				}
			}

			Behavior on implicitHeight {
				NumberAnimation {
					duration: 220
					easing.type: Easing.OutCubic
				}
			}

			Rectangle {
				anchors.fill: parent
				radius: Config.island ? Math.min(width, height) / 2 : 0
				color: !ws.shown ? "transparent" : Config.island ? Theme.primary : Theme.overlay

				Behavior on color {
					ColorAnimation {
						duration: 180
					}
				}
			}

			Rectangle {
				visible: !Config.island && ws.shown
				color: Theme.primary
				width: Config.vertical ? 2 : parent.width
				height: Config.vertical ? parent.height : 2
				x: Config.position === "left" ? parent.width - width : 0
				y: Config.position === "top" ? parent.height - height : 0
			}

			Glyph {
				id: label

				anchors.centerIn: parent
				text: ws.modelData.name
				font.pixelSize: Theme.fontSize - 1
				color: ws.modelData.urgent ? Theme.error : ws.shown && Config.island ? Theme.onPrimary : ws.shown ? Theme.fg : Theme.fgMuted
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: ws.modelData.activate()
			}
		}
	}
}
