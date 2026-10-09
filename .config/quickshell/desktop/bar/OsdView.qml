import QtQuick
import qs
import qs.widgets

// What just changed: its icon in a soft circle, then the level (volume, mic, brightness) or the
// state (Caps Lock, Num Lock).
Row {
	id: root

	readonly property string kind: Panel.osdKind
	readonly property bool muted: Panel.osdMuted
	readonly property bool level: kind !== "caps" && kind !== "num"
	readonly property color tint: muted ? Theme.fgMuted : Theme.primary

	spacing: 14

	Rectangle {
		anchors.verticalCenter: parent.verticalCenter
		width: 38
		height: 38
		radius: 19
		color: Qt.alpha(root.tint, 0.18)

		Glyph {
			anchors.centerIn: parent
			font.pixelSize: 20
			color: root.tint
			text: ({
					volume: root.muted ? "󰖁" : Panel.osdValue < 0.34 ? "󰕿" : Panel.osdValue < 0.67 ? "󰖀" : "󰕾",
					mic: root.muted ? "󰍭" : "󰍬",
					brightness: "󰃠",
					caps: "󰪛",
					num: "󰎠"
				})[root.kind] ?? ""
		}
	}

	Rectangle {
		visible: root.level
		anchors.verticalCenter: parent.verticalCenter
		width: 220
		height: 6
		radius: 3
		color: Qt.alpha(Theme.overlay, 0.8)

		Rectangle {
			width: parent.width * Math.min(1, Panel.osdValue)
			height: parent.height
			radius: parent.radius
			color: root.tint

			Behavior on width {
				NumberAnimation {
					duration: 140
					easing.type: Easing.OutCubic
				}
			}
		}
	}

	Glyph {
		visible: root.level
		anchors.verticalCenter: parent.verticalCenter
		width: 44
		horizontalAlignment: Text.AlignRight
		color: root.muted ? Theme.fgMuted : Theme.fg
		text: root.muted ? "off" : Math.round(Panel.osdValue * 100)
	}

	Text {
		visible: !root.level
		anchors.verticalCenter: parent.verticalCenter
		rightPadding: 6
		text: (root.kind === "caps" ? "Caps Lock " : "Num Lock ") + (root.muted ? "off" : "on")
		color: root.muted ? Theme.fgMuted : Theme.fg
		font.family: Theme.fontSans
		font.pixelSize: 15
		font.weight: Font.Medium
	}
}
