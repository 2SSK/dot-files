import QtQuick
import qs

// An icon in Tabler (`filled` for active states), centred in a square box of its size: the font's
// own advance widths aren't even, which made capsules lopsided.
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
