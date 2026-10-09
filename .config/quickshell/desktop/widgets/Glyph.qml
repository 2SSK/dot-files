import QtQuick
import qs

// An icon: `glyph` (Icons.g(name)) in Tabler, its filled version with `filled` (active states).
Text {
	property string glyph
	property bool filled: false

	text: filled ? Icons.filled(glyph) : glyph
	color: Theme.fg
	font.family: Icons.family
	font.pixelSize: Theme.iconSize
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
}
