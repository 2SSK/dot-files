import QtQuick
import QtQuick.Effects

// A soft drop shadow under a rounded card, filling its parent's anchors like the card.
RectangularShadow {
	property real offsetY: 4

	blur: 24
	offset.y: offsetY
	color: Qt.alpha("black", 0.4)
}
