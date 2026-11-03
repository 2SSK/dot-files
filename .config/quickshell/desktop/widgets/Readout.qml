import QtQuick
import qs

// A glyph and a value (on a side bar the glyph over the value). The value keeps the width of `widest`
// with even-width digits, so the bar doesn't shift as it changes.
Line {
	id: root

	property string glyph
	property string value
	property color tint: Theme.fg
	property string widest: ""

	vertical: Config.vertical
	spacing: Config.vertical ? 0 : 6

	Glyph {
		glyph: root.glyph
		color: root.tint
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
