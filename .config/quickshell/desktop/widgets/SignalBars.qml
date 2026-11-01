import QtQuick
import qs

// A signal's strength as four bars rising left to right, the reached ones lit: readable at any
// strength (Tabler's weak Wi-Fi glyphs shrink to a dot).
Row {
	id: root

	property real strength // 0-1
	property color color: Theme.fg
	property int size: 16 // the tallest bar
	readonly property int lit: strength <= 0 ? 0 : Math.max(1, Math.min(4, Math.ceil(strength * 4)))

	spacing: Math.max(2, Math.round(size / 8))
	height: size

	Repeater {
		model: 4

		Rectangle {
			required property int index

			y: root.size - height // bottoms aligned
			width: Math.max(3, Math.round(root.size / 5))
			height: Math.round(root.size * (index + 1) / 4)
			radius: width / 2
			color: index < root.lit ? root.color : Qt.alpha(root.color, 0.22)
		}
	}
}
