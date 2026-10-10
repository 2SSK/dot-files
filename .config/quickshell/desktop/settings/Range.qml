import QtQuick
import qs

// A slider from `from` to `to` in `step`s, with the value shown by `format`; moved(value) while
// dragging or clicking, released(value) once let go (for what's costly to apply at every step).
Row {
	id: root

	property real from: 0
	property real to: 1
	property real step: 0.1
	property real value
	property var format: v => v
	signal moved(real value)
	signal released(real value)

	spacing: 12

	Item {
		id: track

		anchors.verticalCenter: parent.verticalCenter
		width: 200
		height: 20

		readonly property real ratio: (root.value - root.from) / (root.to - root.from)

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			height: 4
			radius: 2
			color: Qt.alpha(Theme.overlay, 0.9)

			Rectangle {
				width: parent.width * Math.max(0, Math.min(1, track.ratio))
				height: parent.height
				radius: 2
				color: Theme.primary
			}
		}

		Rectangle {
			x: Math.max(0, Math.min(1, track.ratio)) * (track.width - width)
			anchors.verticalCenter: parent.verticalCenter
			width: 16
			height: 16
			radius: 8
			color: Theme.fg
			border.width: 3
			border.color: Theme.primary
		}

		MouseArea {
			anchors.fill: parent
			anchors.margins: -6
			cursorShape: Qt.PointingHandCursor
			function pick(x: real): void {
				const ratio = Math.max(0, Math.min(1, x / track.width));
				const value = Math.round((root.from + ratio * (root.to - root.from)) / root.step) * root.step;
				if (Math.abs(value - root.value) > root.step / 2)
					root.moved(Number(value.toFixed(3)));
			}
			onPressed: event => pick(event.x)
			onPositionChanged: event => pick(event.x)
			onReleased: root.released(root.value)
		}
	}

	// on a whole pixel: centred, Inter's line height would put it between two, blurred
	Text {
		y: Math.round((track.height - height) / 2)
		width: 56
		horizontalAlignment: Text.AlignRight
		text: root.format(root.value)
		color: Theme.fg
		font.family: Theme.fontSans
		font.pixelSize: 13
		font.weight: Font.Medium
		font.features: ({ tnum: 1 })
	}
}
