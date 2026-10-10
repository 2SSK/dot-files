import QtQuick
import qs

// A slider's track: filled up to `ratio` (0–1), a knob on it, dragged or clicked anywhere along it.
// dragged(ratio) as it moves, released once let go. Level (volume, brightness) and Range (settings)
// put their icon, steps and label around it.
Item {
	id: root

	property real ratio
	property color tint: Theme.primary
	property int thickness: 4
	signal dragged(real ratio)
	signal released

	implicitHeight: 20

	Rectangle {
		anchors.verticalCenter: parent.verticalCenter
		width: parent.width
		height: root.thickness
		radius: height / 2
		color: Qt.alpha(Theme.overlay, 0.9)

		Rectangle {
			width: parent.width * Math.max(0, Math.min(1, root.ratio))
			height: parent.height
			radius: height / 2
			color: root.tint
		}
	}

	Rectangle {
		x: Math.max(0, Math.min(1, root.ratio)) * (root.width - width)
		anchors.verticalCenter: parent.verticalCenter
		width: 16
		height: 16
		radius: 8
		color: Theme.fg
		border.width: 3
		border.color: root.tint
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6 // easier to catch than the track itself
		cursorShape: Qt.PointingHandCursor
		function at(px: real): real {
			return Math.max(0, Math.min(1, (px + x) / root.width)); // x: this area's offset on the track
		}
		onPressed: event => root.dragged(at(event.x))
		onPositionChanged: event => root.dragged(at(event.x))
		onReleased: root.released()
	}
}
