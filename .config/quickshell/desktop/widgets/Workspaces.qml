pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs

// Workspaces as dots, no numbers: 1–5 always there (as waybar's persistent ones) so a dot's place
// says which it is, plus any others on this screen. The shown one is a wide accent pill, ones with
// windows are bright, empty ones faint, an urgent one red. A click switches, creating it if needed.
Line {
	id: root

	property ShellScreen screen: null // set by the bar
	// this screen's workspaces; by monitor name, as monitorFor() may return an early copy
	readonly property var here: I3.workspaces.values.filter(ws => ws.monitor?.name === screen?.name)
	readonly property var numbers: [...new Set([1, 2, 3, 4, 5, ...here.map(ws => ws.number).filter(n => n > 0)])].sort((a, b) => a - b)

	vertical: Config.vertical
	spacing: 7

	Repeater {
		model: root.numbers

		delegate: Item {
			id: slot

			required property int modelData

			readonly property I3Workspace workspace: I3.workspaces.values.find(ws => ws.number === modelData) ?? null
			readonly property bool shown: workspace?.active ?? false
			readonly property bool used: workspace !== null && !shown
			readonly property real dot: Math.round(Config.bar.size * 0.3)

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
				color: slot.workspace?.urgent ? Theme.error : slot.shown ? Theme.primary : hover.containsMouse ? Theme.fg : slot.used ? Qt.alpha(Theme.fg, 0.75) : Qt.alpha(Theme.fgMuted, 0.35)

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
				onClicked: I3.dispatch(`workspace number ${slot.modelData}`)
			}
		}
	}
}
