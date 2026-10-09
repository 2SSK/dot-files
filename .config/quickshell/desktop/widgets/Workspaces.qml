pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs

// This screen's workspaces as dots, no numbers: the ones with windows, and the one you're on (i3
// and sway drop a workspace once it's empty and left). The current one is a wide accent pill, an
// urgent one red; a click switches.
Line {
	id: root

	property ShellScreen screen: null // set by the bar
	// I3.workspaces.values doesn't announce its changes: re-read it on every i3 event
	property int revision: 0
	readonly property var here: {
		revision;
		return I3.workspaces.values.filter(ws => ws.monitor?.name === screen?.name && ws.number > 0).sort((a, b) => a.number - b.number);
	}

	Connections {
		target: I3

		function onRawEvent(): void {
			root.revision++;
		}
		function onFocusedWorkspaceChanged(): void {
			root.revision++;
		}
	}

	vertical: Config.vertical
	spacing: 7

	Repeater {
		model: root.here

		delegate: Item {
			id: slot

			required property I3Workspace modelData

			readonly property I3Workspace workspace: modelData
			readonly property bool shown: workspace.active
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
				color: slot.workspace.urgent ? Theme.error : slot.shown ? Theme.primary : hover.containsMouse ? Theme.fg : Qt.alpha(Theme.fg, 0.6)

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
				onClicked: slot.workspace.activate()
			}
		}
	}
}
