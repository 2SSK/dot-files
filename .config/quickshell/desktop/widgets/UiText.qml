import QtQuick
import qs

// Text in the shell's interface: the body font, size and weight from Settings → Appearance, hinted
// like every other text (Theme.hinting). A use sets only what differs: a heading's font, a label's
// size, a muted colour. (The bar's figures are Label: the bar font, even-width digits.)
Text {
	color: Theme.fg
	font.family: Theme.fontSans
	font.hintingPreference: Theme.hinting
	font.pixelSize: Theme.textBody
	font.weight: Theme.textWeight
}
