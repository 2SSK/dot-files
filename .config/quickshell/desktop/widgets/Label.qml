import QtQuick
import qs

// Bar text (the clock, values): the UI font with even-width digits; icons stay in Glyph.
Text {
	color: Theme.fg
	font.family: Theme.fontSans
	font.pixelSize: Theme.fontSize
	font.weight: Font.DemiBold
	font.features: ({ tnum: 1 })
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
}
