import QtQuick
import qs
import qs.widgets

// A level that just changed: what it is, how much, and whether it's muted.
Row {
	spacing: 14

	Glyph {
		anchors.verticalCenter: parent.verticalCenter
		width: 24
		font.pixelSize: Theme.fontSize + 6
		color: Panel.osdMuted ? Theme.fgMuted : Theme.primary
		text: Panel.osdKind === "brightness" ? "󰃠" : Panel.osdKind === "mic" ? (Panel.osdMuted ? "󰍭" : "󰍬") : Panel.osdMuted ? "󰖁" : Panel.osdValue < 0.34 ? "󰕿" : Panel.osdValue < 0.67 ? "󰖀" : "󰕾"
	}

	Rectangle {
		anchors.verticalCenter: parent.verticalCenter
		width: 220
		height: 6
		radius: 3
		color: Qt.alpha(Theme.overlay, 0.8)

		Rectangle {
			width: parent.width * Math.min(1, Panel.osdValue)
			height: parent.height
			radius: parent.radius
			color: Panel.osdMuted ? Theme.fgMuted : Theme.primary

			Behavior on width {
				NumberAnimation {
					duration: 140
					easing.type: Easing.OutCubic
				}
			}
		}
	}

	Glyph {
		anchors.verticalCenter: parent.verticalCenter
		width: 44
		horizontalAlignment: Text.AlignRight
		color: Panel.osdMuted ? Theme.fgMuted : Theme.fg
		text: Panel.osdMuted ? "mute" : Math.round(Panel.osdValue * 100)
	}
}
