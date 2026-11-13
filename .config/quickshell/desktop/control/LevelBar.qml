import QtQuick
import qs
import qs.widgets

// A level (not the shell's Bar): its icon at the left (a click on it mutes), a slim track filled in
// the accent to the value with a small handle, and the percentage at the right. Drag or click the
// track to set it; the row is easy to hit though the track is thin.
Item {
	id: root

	property string glyph
	property real value // 0–1
	property bool muted
	signal moved(real value)
	signal iconClicked

	readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))

	height: 28

	Glyph {
		id: icon

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		width: 20
		glyph: root.glyph
		color: root.muted ? Theme.fgMuted : Theme.fg
		font.pixelSize: 16

		MouseArea {
			anchors.fill: parent
			anchors.margins: -6
			cursorShape: Qt.PointingHandCursor
			onClicked: root.iconClicked()
		}
	}

	Item {
		id: track

		anchors.left: icon.right
		anchors.leftMargin: 12
		anchors.right: percent.left
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		height: 14

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			height: 6
			radius: 3
			color: Qt.alpha(Theme.fg, 0.12)

			Rectangle {
				width: parent.width * root.shown
				height: parent.height
				radius: parent.radius
				color: root.muted ? Theme.fgMuted : Theme.primary

				Behavior on width {
					enabled: !drag.pressed
					NumberAnimation {
						duration: Theme.quick
						easing.type: Theme.curve
					}
				}
			}
		}

		Rectangle {
			x: track.width * root.shown - width / 2
			anchors.verticalCenter: parent.verticalCenter
			width: drag.pressed || drag.containsMouse ? 14 : 12
			height: width
			radius: width / 2
			color: root.muted ? Theme.fgMuted : Theme.fg

			Behavior on width {
				NumberAnimation {
					duration: Theme.quick
					easing.type: Theme.curve
				}
			}
		}

		MouseArea {
			id: drag

			anchors.fill: parent
			anchors.topMargin: -7
			anchors.bottomMargin: -7
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			function set(x: real): void {
				root.moved(Math.max(0, Math.min(1, x / width)));
			}
			onPressed: mouse => set(mouse.x)
			onPositionChanged: mouse => { if (pressed) set(mouse.x); }
		}
	}

	Label {
		id: percent

		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: 40
		horizontalAlignment: Text.AlignRight
		text: root.muted ? "off" : Math.round(root.shown * 100) + "%"
		color: root.muted ? Theme.fgMuted : Theme.fgMuted
		font.pixelSize: Theme.textCaption
		font.features: ({ tnum: 1 })
	}
}
