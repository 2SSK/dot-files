import QtQuick
import qs

// Text in the shell's interface, in the body font, size and weight from Settings, hinted like all text.
// A use sets only what differs; the bar's figures use Label instead.
Text {
	color: Theme.fg
	font.family: Theme.fontSans
	font.hintingPreference: Theme.hinting
	font.pixelSize: Theme.textBody
	font.weight: Theme.textWeight
}
