import QtQuick

// A soft drop shadow under a rounded card, filling its parent's anchors like the card. It is Qt
// 6.9's RectangularShadow, loaded by file name: on an older Qt (Debian 13 has 6.8) that load fails
// on its own and the card simply has no shadow, instead of the whole shell failing to load.
Item {
	id: root

	property real radius
	property real blur: 24
	property real offsetY: 4
	property color color: Qt.alpha("black", 0.4)

	Loader {
		anchors.fill: parent
		source: "ShadowQt69.qml"
	}
}
