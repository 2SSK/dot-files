import QtQuick
import qs
import qs.widgets

// A thick level bar (not the shell's Bar), as macOS draws them: a pill filled in the text colour to the value, its icon
// inside at the left (a click on it mutes) and the percentage at the right. Drag or click to set.
Rectangle {
	id: root

	property string glyph
	property real value // 0–1
	property bool muted
	signal moved(real value)
	signal iconClicked

	readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))

	height: 30
	radius: height / 2
	color: Qt.alpha(Theme.fg, 0.1)
	clip: true

	Rectangle {
		width: Math.max(root.height, root.width * root.shown)
		height: parent.height
		radius: parent.radius
		color: root.muted ? Qt.alpha(Theme.fg, 0.3) : Theme.fg

		Behavior on width {
			enabled: !drag.pressed
			NumberAnimation {
				duration: Theme.quick
				easing.type: Theme.curve
			}
		}
	}

	MouseArea {
		id: drag

		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		function set(x: real): void {
			root.moved(Math.max(0, Math.min(1, x / width)));
		}
		onPressed: mouse => set(mouse.x)
		onPositionChanged: mouse => { if (pressed) set(mouse.x); }
	}

	// the icon sits on the fill (which always reaches past it), so it takes the background's colour
	Glyph {
		x: (root.height - width) / 2
		anchors.verticalCenter: parent.verticalCenter
		glyph: root.glyph
		color: Theme.bg
		font.pixelSize: 16

		MouseArea {
			anchors.fill: parent
			anchors.margins: -6
			cursorShape: Qt.PointingHandCursor
			onClicked: root.iconClicked()
		}
	}

	Label {
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		text: root.muted ? "off" : Math.round(root.shown * 100) + "%"
		color: root.width * root.shown > root.width - 50 ? Theme.bg : Theme.fgMuted
		font.pixelSize: Theme.textCaption
		font.features: ({ tnum: 1 })
	}
}
