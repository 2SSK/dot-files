import QtQuick
import qs

// A titled group of settings rows.
Column {
	id: root

	property string title

	width: parent?.width ?? 0
	spacing: 4

	Text {
		bottomPadding: 6
		text: root.title
		color: Theme.fgMuted
		font.family: Theme.fontHeading
		font.hintingPreference: Theme.hinting
		font.pixelSize: Theme.textLabel
		font.weight: Font.DemiBold
		font.capitalization: Font.AllUppercase
		font.letterSpacing: 0.8
	}
}
