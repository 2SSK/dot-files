import QtQuick
import qs

// A glyph and a value; the static style shows an accent word instead ("cpu 12%"). The value keeps the
// width of `widest` with even-width digits, so the bar doesn't shift as it changes.
Line {
	id: root

	property string glyph
	property string label
	property string value
	property color tint: Theme.fg
	property string widest: ""

	vertical: Config.vertical
	spacing: Config.vertical ? 0 : 6

	Glyph {
		visible: Config.island || Config.vertical
		glyph: root.glyph
		color: root.tint
	}

	Label {
		font.family: Theme.fontBar
		font.weight: Theme.barWeight
		visible: !Config.island && !Config.vertical
		text: root.label
		color: Theme.primary
	}

	Label {
		id: value

		font.family: Theme.fontBar
		font.weight: Theme.barWeight
		visible: root.value !== ""
		width: Math.max(implicitWidth, widest.width)
		text: root.value
		color: root.tint
		font.pixelSize: Config.vertical ? Theme.fontSize - 3 : Theme.fontSize

		TextMetrics {
			id: widest

			font: value.font
			text: root.widest
		}
	}
}
