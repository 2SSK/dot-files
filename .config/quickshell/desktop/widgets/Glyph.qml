import QtQuick
import qs

// An icon (Icons.g(name)) in Phosphor Light, or Phosphor Fill with `filled` (active states).
Text {
	property bool filled: false

	color: Theme.fg
	font.family: filled ? Icons.fill : Icons.light
	font.pixelSize: Theme.iconSize
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
}
