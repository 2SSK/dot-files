import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.widgets

// A ringing alarm, under the middle of the bar on the focused screen: its label and time, Stop and
// Snooze (5 minutes). It stays until one of them.
PopupWindow {
	id: root

	required property PanelWindow bar
	required property Item island

	readonly property bool open: Alarms.ringing !== null && WindowManager.focusedOutput === bar.screen?.name
	readonly property int pad: 28
	property bool shown: false
	property var alarm: null // stays while it slides away

	onOpenChanged: {
		if (open) {
			alarm = Alarms.ringing;
			shown = true;
		} else {
			hide.restart();
		}
	}

	Timer {
		id: hide

		interval: 300
		onTriggered: if (!root.open) root.shown = false
	}

	anchor.window: bar
	anchor.rect.x: island.x + island.width / 2 - implicitWidth / 2
	anchor.rect.y: Config.position === "bottom" ? island.y - implicitHeight + 14 : island.y + island.height - 14
	implicitWidth: card.width + 2 * pad
	implicitHeight: card.height + 2 * pad
	visible: shown
	color: "transparent"
	mask: Region {
		item: card
		radius: card.radius
	}

	RectangularShadow {
		anchors.fill: card
		radius: card.radius
		blur: 24
		offset.y: 4
		color: Qt.alpha("black", 0.45)
		opacity: card.opacity
	}

	Rectangle {
		id: card

		x: root.pad
		y: root.pad + (root.open ? 0 : -14)
		width: 380
		height: 92
		radius: 18
		opacity: root.open ? 1 : 0
		color: Qt.alpha(Theme.bg, 0.96)
		border.width: 1
		border.color: Theme.primary

		Behavior on y {
			NumberAnimation {
				duration: 260
				easing.type: Easing.OutCubic
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: 200
			}
		}

		Rectangle {
			id: badge

			x: 18
			anchors.verticalCenter: parent.verticalCenter
			width: 48
			height: 48
			radius: 24
			color: Qt.alpha(Theme.primary, 0.18)

			Glyph {
				anchors.centerIn: parent
				glyph: Icons.g("alarm")
				filled: true
				font.pixelSize: 24
				color: Theme.primary

				SequentialAnimation on rotation {
					running: root.open
					loops: Animation.Infinite

					NumberAnimation {
						to: 12
						duration: 90
					}

					NumberAnimation {
						to: -12
						duration: 180
					}

					NumberAnimation {
						to: 0
						duration: 90
					}

					PauseAnimation {
						duration: 700
					}
				}
			}
		}

		Column {
			anchors.left: badge.right
			anchors.leftMargin: 14
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2

			Text {
				text: root.alarm?.label ?? ""
				color: Theme.fg
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 16
				font.weight: Font.DemiBold
			}

			Label {
				text: root.alarm?.time ?? ""
				color: Theme.fgMuted
				font.pixelSize: 13
				font.weight: Font.Medium
			}
		}

		Row {
			anchors.right: parent.right
			anchors.rightMargin: 16
			anchors.verticalCenter: parent.verticalCenter
			spacing: 8

			Repeater {
				model: [
					{ label: "Snooze", act: () => Alarms.snooze(), accent: false },
					{ label: "Stop", act: () => Alarms.stop(), accent: true }
				]

				delegate: Rectangle {
					id: button

					required property var modelData

					width: buttonLabel.implicitWidth + 28
					height: 34
					radius: 17
					color: modelData.accent ? Theme.primary : buttonHover.hovered ? Qt.alpha(Theme.fg, 0.12) : Qt.alpha(Theme.overlay, 0.9)

					Text {
						id: buttonLabel

						anchors.centerIn: parent
						text: button.modelData.label
						color: button.modelData.accent ? Theme.primaryText : Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 13
						font.weight: Font.DemiBold
					}

					HoverHandler {
						id: buttonHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: button.modelData.act()
					}
				}
			}
		}
	}
}
