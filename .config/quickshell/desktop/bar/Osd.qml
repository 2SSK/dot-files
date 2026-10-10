import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// A slim pill at the top right (or the end of a vertical bar) for what just changed: the volume,
// the mic, the brightness, Caps Lock or Num Lock. It slides in, then out after osd.timeout.
PopupWindow {
	id: root

	required property PanelWindow bar

	readonly property bool open: Panel.osdShown && WindowManager.focusedOutput === bar.screen?.name
	readonly property string position: Config.position
	readonly property string kind: Panel.osdKind
	readonly property bool muted: Panel.osdMuted
	readonly property bool level: kind !== "caps" && kind !== "num"
	readonly property color tint: muted ? Theme.fgMuted : Theme.primary
	readonly property int pad: 28 // room for the shadow

	// mapped when it opens, so it lands above every window (X stacks by mapping order), and unmapped
	// once it has faded
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
	visible: shown
	color: "transparent"
	mask: Region {
		item: card
		radius: card.radius // the shape picom blurs behind
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

		Shadow {
			anchors.fill: card
			radius: card.radius
			blur: 24
			offsetY: 4
			color: Qt.alpha("black", 0.4)
		}

		// a slim pill: the icon, then the level as a thin bar and its percentage (Caps Lock and Num
		// Lock: their name and on or off)
		Rectangle {
			id: card

			x: root.pad + (root.open ? 0 : 24)
			y: root.pad
			width: row.implicitWidth + 32
			height: 40
			radius: height / 2
			color: Qt.alpha(Theme.bg, 0.96)
			border.width: 1
			border.color: Qt.alpha(Theme.border, 0.7)

			Behavior on x {
				NumberAnimation {
					duration: 240
					easing.type: Easing.OutCubic
				}
			}

			Row {
				id: row

				x: 16
				anchors.verticalCenter: parent.verticalCenter
				spacing: 12

				Glyph {
					anchors.verticalCenter: parent.verticalCenter
					font.pixelSize: 17
					color: root.tint
					glyph: ({
							volume: root.muted ? Icons.g("volume-off") : Panel.osdValue < 0.5 ? Icons.g("volume-2") : Icons.g("volume"),
							mic: root.muted ? Icons.g("microphone-off") : Icons.g("microphone"),
							brightness: Icons.g("brightness-up"),
							caps: Icons.g("arrow-big-up-line"),
							num: Icons.g("hash")
						})[root.kind] ?? ""
				}

				Rectangle {
					visible: root.level
					anchors.verticalCenter: parent.verticalCenter
					width: 150
					height: 4
					radius: 2
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
					anchors.verticalCenter: parent.verticalCenter
					width: root.level ? 36 : implicitWidth
					horizontalAlignment: root.level ? Text.AlignRight : Text.AlignLeft
					text: root.level ? (root.muted ? "off" : Math.round(Panel.osdValue * 100) + "%") : `${root.kind === "caps" ? "Caps Lock" : "Num Lock"} ${root.muted ? "off" : "on"}`
					color: root.muted ? Theme.fgMuted : Theme.fg
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textLabel
					font.weight: Font.Medium
					font.features: ({ tnum: 1 })
				}
			}
		}
	}
}
