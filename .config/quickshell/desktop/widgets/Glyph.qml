import QtQuick
import qs

// An icon: `glyph` (Icons.g(name)) in Tabler, its filled version with `filled` (active states). It
// takes a square box of its size, the icon centred in it: the font's own advance widths aren't
// even, which made capsules lopsided.
Item {
	property string glyph
	property bool filled: false
	property alias color: icon.color
	property alias font: icon.font

	implicitWidth: icon.font.pixelSize
	implicitHeight: icon.implicitHeight

	Text {
		id: icon

		anchors.centerIn: parent
		text: parent.filled ? Icons.filled(parent.glyph) : parent.glyph
		color: Theme.fg
		font.family: Icons.family
		font.pixelSize: Theme.iconSize
	}
}
