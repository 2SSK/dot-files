import QtQuick
import qs

// A glyph and a value. The static style uses a word in the accent colour instead of the glyph,
// as polybar did ("cpu 12%"); a vertical bar stacks them. The value keeps the width of `widest`
// (e.g. "88%") with even-width digits, so the bar doesn't shift as it changes.
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
