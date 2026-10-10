import QtQuick
import qs
import qs.widgets

// A level slider: its icon (a click on it mutes), a track to drag or click, and the percentage.
Item {
	id: root

	property string glyph
	property real value // 0–1
	property bool muted
	signal moved(real value)
	signal iconClicked

	height: 36

	IconButton {
		id: icon

		anchors.verticalCenter: parent.verticalCenter
		glyph: root.glyph
		glyphSize: 17
		glyphColor: root.muted ? Theme.fgMuted : Theme.fg
		onClicked: root.iconClicked()
	}

	Track {
		anchors.left: icon.right
		anchors.leftMargin: 10
		anchors.right: percent.left
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		ratio: root.value
		thickness: 6
		tint: root.muted ? Theme.fgMuted : Theme.primary
		onDragged: ratio => root.moved(ratio)
	}

	Label {
		id: percent

		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: 42
		horizontalAlignment: Text.AlignRight
		text: root.muted ? "off" : Math.round(root.value * 100) + "%"
		color: root.muted ? Theme.fgMuted : Theme.fg
		font.pixelSize: Theme.textLabel
	}
}
