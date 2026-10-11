import QtQuick
import qs

// Bar text (the clock, values): the UI font with even-width digits; icons stay in Glyph.
UiText {
	font.family: Theme.fontHeading
	font.pixelSize: Theme.fontSize
	font.weight: Font.DemiBold
	font.features: ({ tnum: 1 })
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
}
