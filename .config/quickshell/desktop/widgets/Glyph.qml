import QtQuick
import qs

// Bar text: the mono font (Nerd glyphs), bold, as waybar and polybar had it.
Text {
	color: Theme.fg
	font.family: Theme.fontMono
	font.pixelSize: Theme.fontSize
	font.weight: Font.Bold
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
}
