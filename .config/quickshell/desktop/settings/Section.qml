import QtQuick
import qs
import qs.widgets

// A titled group of settings rows.
Column {
	id: root

	property string title

	width: parent?.width ?? 0
	spacing: 4

	UiText {
		bottomPadding: 6
		text: root.title
		color: Theme.fgMuted
		font.family: Theme.fontHeading
		font.pixelSize: Theme.textLabel
		font.weight: Font.DemiBold
		font.capitalization: Font.AllUppercase
		font.letterSpacing: 0.8
	}
}
