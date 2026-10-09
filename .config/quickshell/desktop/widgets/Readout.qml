import QtQuick
import qs

// A glyph and a value. The static style uses a word in the accent colour instead of the glyph,
// as polybar did ("cpu 12%"); a vertical bar stacks them.
Line {
	id: root

	property string glyph
	property string label
	property string value
	property color tint: Theme.fg

	vertical: Config.vertical
	spacing: Config.vertical ? 0 : 6

	Glyph {
		text: Config.island || Config.vertical ? root.glyph : root.label
		color: Config.island || Config.vertical ? root.tint : Theme.primary
	}

	Glyph {
		visible: root.value !== ""
		text: root.value
		color: root.tint
		font.pixelSize: Config.vertical ? Theme.fontSize - 3 : Theme.fontSize
	}
}
