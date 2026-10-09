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

	Rectangle {
		id: icon

		anchors.verticalCenter: parent.verticalCenter
		width: 34
		height: 34
		radius: 17
		color: iconHover.hovered ? Qt.alpha(Theme.fg, 0.1) : "transparent"

		Glyph {
			anchors.centerIn: parent
			glyph: root.glyph
			font.pixelSize: 17
			font.weight: Font.Normal
			color: root.muted ? Theme.fgMuted : Theme.fg
		}

		HoverHandler {
			id: iconHover
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: root.iconClicked()
		}
	}

	Item {
		id: track

		anchors.left: icon.right
		anchors.leftMargin: 10
		anchors.right: percent.left
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		height: 20

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			height: 6
			radius: 3
			color: Qt.alpha(Theme.overlay, 0.9)

			Rectangle {
				width: parent.width * Math.max(0, Math.min(1, root.value))
				height: parent.height
				radius: 3
				color: root.muted ? Theme.fgMuted : Theme.primary
			}
		}

		Rectangle {
			x: Math.max(0, Math.min(1, root.value)) * (track.width - width)
			anchors.verticalCenter: parent.verticalCenter
			width: 16
			height: 16
			radius: 8
			color: Theme.fg
			border.width: 3
			border.color: root.muted ? Theme.fgMuted : Theme.primary
		}

		MouseArea {
			anchors.fill: parent
			anchors.margins: -6
			cursorShape: Qt.PointingHandCursor
			onPressed: event => root.moved(Math.max(0, Math.min(1, event.x / track.width)))
			onPositionChanged: event => root.moved(Math.max(0, Math.min(1, event.x / track.width)))
		}
	}

	Label {
		id: percent

		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: 42
		horizontalAlignment: Text.AlignRight
		text: root.muted ? "off" : Math.round(root.value * 100) + "%"
		color: root.muted ? Theme.fgMuted : Theme.fg
		font.pixelSize: 13
	}
}
