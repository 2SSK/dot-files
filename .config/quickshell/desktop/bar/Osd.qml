import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.I3
import qs
import qs.widgets

// A small card at the top right (or the end of a vertical bar) for what just changed: the volume,
// the mic, the brightness, Caps Lock or Num Lock. It slides in, then out after osd.timeout.
PopupWindow {
	id: root

	required property PanelWindow bar

	readonly property bool open: Panel.osdShown && I3.focusedMonitor?.name === bar.screen?.name
	readonly property string position: Config.position
	readonly property string kind: Panel.osdKind
	readonly property bool muted: Panel.osdMuted
	readonly property bool level: kind !== "caps" && kind !== "num"
	readonly property color tint: muted ? Theme.fgMuted : Theme.primary
	readonly property int pad: 28 // room for the shadow

	// The window stays mapped (the first map of a shaped popup can come up blank); while closed its
	// shape is empty, so it's invisible and lets clicks through.
	property bool shown: false

	onOpenChanged: open ? shown = true : hide.restart()

	Timer {
		id: hide

		interval: 300
		onTriggered: if (!root.open) root.shown = false
	}

	anchor.window: bar
	anchor.rect.x: position === "right" ? -implicitWidth + 12 : position === "left" ? bar.width - 12 : bar.width - implicitWidth
	anchor.rect.y: position === "bottom" ? -implicitHeight + 12 : position === "top" ? bar.height - 14 : 0
	implicitWidth: card.width + 2 * pad
	implicitHeight: card.height + 2 * pad
	visible: true
	color: "transparent"
	mask: Region {
		item: root.shown ? card : null
	}

	// card and shadow fade in together; the card slides by its x (the window's shape follows
	// geometry, not transforms)
	Item {
		id: slide

		anchors.fill: parent
		opacity: root.open ? 1 : 0

		Behavior on opacity {
			NumberAnimation {
				duration: 200
			}
		}

		RectangularShadow {
			anchors.fill: card
			radius: card.radius
			blur: 24
			offset.y: 4
			color: Qt.alpha("black", 0.4)
		}

		Rectangle {
			id: card

			x: root.pad + (root.open ? 0 : 36)
			y: root.pad
			width: 300
			height: 72
			radius: 16
			color: Qt.alpha(Theme.bg, 0.96)
			border.width: 1
			border.color: Qt.alpha(Theme.border, 0.7)

			Behavior on x {
				NumberAnimation {
					duration: 280
					easing.type: Easing.OutCubic
				}
			}

			Rectangle {
				id: badge

				anchors.left: parent.left
				anchors.leftMargin: 16
				anchors.verticalCenter: parent.verticalCenter
				width: 40
				height: 40
				radius: 20
				color: Qt.alpha(root.tint, 0.16)

				Glyph {
					anchors.centerIn: parent
					font.pixelSize: 20
					color: root.tint
					text: ({
							volume: root.muted ? "\u{F0581}" : Panel.osdValue < 0.34 ? "\u{F057F}" : Panel.osdValue < 0.67 ? "\u{F0580}" : "\u{F057E}",
							mic: root.muted ? "\u{F036D}" : "\u{F036C}",
							brightness: "\u{F00E0}",
							caps: "\u{F0A9B}",
							num: "\u{F03A0}"
						})[root.kind] ?? ""
				}
			}

			Column {
				anchors.left: badge.right
				anchors.leftMargin: 14
				anchors.right: parent.right
				anchors.rightMargin: 18
				anchors.verticalCenter: parent.verticalCenter
				spacing: 9

				Item {
					width: parent.width
					height: title.implicitHeight

					Text {
						id: title

						text: ({
								volume: "Volume",
								mic: "Microphone",
								brightness: "Brightness",
								caps: "Caps Lock",
								num: "Num Lock"
							})[root.kind] ?? ""
						color: Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 15
						font.weight: Font.DemiBold
					}

					Text {
						anchors.right: parent.right
						anchors.baseline: title.baseline
						text: root.level ? (root.muted ? "Muted" : Math.round(Panel.osdValue * 100) + "%") : (root.muted ? "Off" : "On")
						color: root.muted ? Theme.fgMuted : Theme.primary
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: Font.Medium
					}
				}

				Rectangle {
					visible: root.level
					width: parent.width
					height: 5
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

				Text {
					visible: !root.level
					text: root.kind === "caps" ? (root.muted ? "Typing in lower case" : "Typing in capitals") : (root.muted ? "The keypad moves the cursor" : "The keypad types numbers")
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
				}
			}
		}
	}
}
