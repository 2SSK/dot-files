pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.I3
import Quickshell.Services.Notifications
import qs
import qs.services
import qs.widgets

// The notification centre, under the end of the bar: Do Not Disturb, clear all, and the history,
// newest first. It covers the screen while open (transparent) so a click anywhere else closes it.
PopupWindow {
	id: root

	required property PanelWindow bar
	required property Item island

	readonly property bool open: Panel.centerOpen && I3.focusedMonitor?.name === bar.screen?.name
	property bool shown: false

	onOpenChanged: {
		if (open) {
			shown = true;
			Notifications.unread = 0;
		} else {
			hide.restart();
		}
	}

	Timer {
		id: hide

		interval: 240
		onTriggered: if (!root.open) root.shown = false
	}

	anchor.window: bar
	anchor.rect.x: 0
	anchor.rect.y: Config.position === "bottom" ? bar.height - implicitHeight : 0
	implicitWidth: bar.screen.width
	implicitHeight: bar.screen.height
	visible: shown
	color: "transparent"

	MouseArea {
		anchors.fill: parent
		onClicked: Panel.centerOpen = false
	}

	RectangularShadow {
		anchors.fill: panel
		radius: panel.radius
		blur: 26
		offset.y: 4
		color: Qt.alpha("black", 0.45)
		opacity: panel.opacity
	}

	Rectangle {
		id: panel

		readonly property real edge: Panel.barShown ? Config.bar.size + (Config.island ? 6 : 0) + 8 : 8

		width: 400
		height: Math.min(root.height * 0.7, header.height + list.contentHeight + 40)
		x: Math.min(root.width - width - 8, root.island.x + root.island.width - width)
		y: Config.position === "bottom" ? root.height - edge - height + (root.open ? 0 : 12) : edge + (root.open ? 0 : -12)
		radius: 18
		color: Qt.alpha(Theme.bg, 0.97)
		border.width: 1
		border.color: Qt.alpha(Theme.border, 0.8)
		opacity: root.open ? 1 : 0

		Behavior on y {
			NumberAnimation {
				duration: 220
				easing.type: Easing.OutCubic
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: 180
			}
		}

		// clicks on the panel stay on it
		MouseArea {
			anchors.fill: parent
		}

		Item {
			id: header

			x: 16
			y: 14
			width: parent.width - 32
			height: 32

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: "Notifications"
				color: Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 16
				font.weight: Font.DemiBold
			}

			Row {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				spacing: 8

				// Do Not Disturb
				Rectangle {
					width: dnd.implicitWidth + 20
					height: 28
					radius: 14
					color: Notifications.dnd ? Theme.primary : Qt.alpha(Theme.overlay, 0.9)

					Row {
						id: dnd

						anchors.centerIn: parent
						spacing: 6

						Glyph {
							text: Notifications.dnd ? "\u{EC08}" : "\u{EAA2}"
							font.pixelSize: 13
							font.weight: Font.Normal
							color: Notifications.dnd ? Theme.onPrimary : Theme.fg
						}

						Text {
							text: "Do Not Disturb"
							color: Notifications.dnd ? Theme.onPrimary : Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 12
							font.weight: Font.Medium
						}
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Notifications.dnd = !Notifications.dnd
					}
				}

				Rectangle {
					visible: Notifications.history.length > 0
					width: clear.implicitWidth + 20
					height: 28
					radius: 14
					color: clearHover.hovered ? Theme.error : Qt.alpha(Theme.overlay, 0.9)

					Text {
						id: clear

						anchors.centerIn: parent
						text: "Clear"
						color: clearHover.hovered ? Theme.bg : Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 12
						font.weight: Font.Medium
					}

					HoverHandler {
						id: clearHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Notifications.clear()
					}
				}
			}
		}

		ListView {
			id: list

			x: 12
			y: header.y + header.height + 12
			width: parent.width - 24
			height: parent.height - y - 12
			clip: true
			spacing: 8
			model: Notifications.history
			boundsBehavior: Flickable.StopAtBounds

			delegate: NotificationCard {
				required property Notification modelData

				width: list.width
				notification: modelData
				onFinished: modelData.dismiss()
			}
		}

		Column {
			anchors.centerIn: list
			visible: Notifications.history.length === 0
			spacing: 8

			Glyph {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Notifications.dnd ? "\u{EC08}" : "\u{EAA2}"
				font.pixelSize: 28
				font.weight: Font.Normal
				color: Theme.fgMuted
			}

			Text {
				text: "No notifications"
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 13
			}
		}
	}
}
