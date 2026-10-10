import QtQuick
import qs
import qs.widgets

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

	Track {
		id: track

		anchors.verticalCenter: parent.verticalCenter
		width: 200
		ratio: (root.value - root.from) / (root.to - root.from)
		onDragged: ratio => {
			const value = Math.round((root.from + ratio * (root.to - root.from)) / root.step) * root.step;
			if (Math.abs(value - root.value) > root.step / 2)
				root.moved(Number(value.toFixed(3)));
		}
		onReleased: root.released(root.value)
	}

	// on a whole pixel: centred, Inter's line height would put it between two, blurred
	Text {
		y: Math.round((track.height - height) / 2)
		width: 56
		horizontalAlignment: Text.AlignRight
		text: root.format(root.value)
		color: Theme.fg
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.pixelSize: 13
		font.weight: Font.Medium
		font.features: ({ tnum: 1 })
	}
}
