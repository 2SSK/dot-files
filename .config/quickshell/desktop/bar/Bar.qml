import QtQuick
import Quickshell
import qs

// One screen's bar, on any edge. Island: a rounded pill floating off the edge, waybar-like. Static:
// the whole edge, polybar-like. i3 reserves a dock's full window, so the window is only as big as
// the bar; what the island grows into (OSD, power menu) is the Expansion popup over the windows.
PanelWindow {
	id: bar

	required property ShellScreen modelData

	readonly property string position: Config.position
	readonly property bool vertical: Config.vertical
	readonly property int size: Config.bar.size
	readonly property int gap: Config.island ? 6 : 0 // the island's distance from the screen edge
	readonly property real edgeLength: vertical ? modelData.height : modelData.width
	readonly property real length: !Config.island ? edgeLength : Math.min(edgeLength - 2 * gap, Math.max(content.naturalLength, Config.bar.length * edgeLength))

	screen: modelData
	anchors.top: position !== "bottom"
	anchors.bottom: position !== "top"
	anchors.left: position !== "right"
	anchors.right: position !== "left"
	implicitWidth: vertical ? size + gap : 0
	implicitHeight: vertical ? 0 : size + gap
	color: "transparent"
	mask: Region {
		item: shape
	}

	Rectangle {
		id: shape

		width: bar.vertical ? bar.size : bar.length
		height: bar.vertical ? bar.length : bar.size
		x: !bar.vertical ? (parent.width - width) / 2 : bar.position === "left" ? bar.gap : 0
		y: bar.vertical ? (parent.height - height) / 2 : bar.position === "top" ? bar.gap : 0
		radius: Config.island ? bar.size / 2 : 0
		color: Qt.alpha(Theme.bg, Config.bar.opacity)
		border.width: Config.island ? 1 : 0
		border.color: Qt.alpha(Theme.border, 0.6)

		BarContent {
			id: content

			anchors.fill: parent
			screen: bar.modelData
		}
	}

	Expansion {
		bar: bar
		island: shape
	}
}
