pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs
import qs.services
import qs.widgets

// One notification: the app's image or icon, the title, the text, how long ago and from which
// app, a close button, and the app's actions. A click runs its default action. Used by the popups
// and the notification centre.
Rectangle {
	id: root

	required property Notification notification
	property bool popup: false
	readonly property bool hovered: hover.hovered
	readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
	readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default")
	property real now: Date.now()

	signal finished

	implicitWidth: 360
	implicitHeight: content.implicitHeight + 28
	radius: 16
	color: popup ? Qt.alpha(Theme.bg, 0.97) : Qt.alpha(Theme.surface, hover.hovered ? 0.95 : 0.7)
	border.width: popup || critical ? 1 : 0
	border.color: critical ? Theme.error : Qt.alpha(Theme.border, 0.8)

	Timer {
		interval: 30000
		running: !root.popup
		repeat: true
		onTriggered: root.now = Date.now()
	}

	function ago(): string {
		const seconds = Math.max(0, (root.now - (Notifications.received[root.notification?.id] ?? root.now)) / 1000);
		return seconds < 60 ? "now" : seconds < 3600 ? `${Math.floor(seconds / 60)}m` : seconds < 86400 ? `${Math.floor(seconds / 3600)}h` : `${Math.floor(seconds / 86400)}d`;
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: {
			const action = (root.notification?.actions ?? []).find(a => a.identifier === "default");
			if (action)
				action.invoke();
			root.finished();
		}
	}

	Row {
		id: content

		x: 14
		y: 14
		width: parent.width - 28
		spacing: 12

		// the app's image, else its icon, else a bell
		Item {
			width: 36
			height: 36

			Rectangle {
				anchors.fill: parent
				radius: 18
				color: Qt.alpha(root.critical ? Theme.error : Theme.primary, 0.16)
				visible: !image.visible
			}

			Glyph {
				anchors.centerIn: parent
				visible: !image.visible
				glyph: Icons.g("bell")
				font.pixelSize: 18
				font.weight: Font.Normal
				color: root.critical ? Theme.error : Theme.primary
			}

			IconImage {
				id: image

				anchors.fill: parent
				visible: status === Image.Ready
				source: root.notification?.image || (root.notification?.appIcon ? Quickshell.iconPath(root.notification.appIcon, true) : "")
			}
		}

		Column {
			width: parent.width - 48
			spacing: 4

			Item {
				width: parent.width
				height: summary.implicitHeight

				Text {
					id: summary

					width: parent.width - meta.width - 30
					text: root.notification?.summary ?? ""
					elide: Text.ElideRight
					color: Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 14
					font.weight: Font.DemiBold
				}

				Text {
					id: meta

					anchors.right: parent.right
					anchors.rightMargin: 24
					anchors.baseline: summary.baseline
					text: root.ago()
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 11
				}

				// close: dismissed for good
				Glyph {
					anchors.right: parent.right
					anchors.verticalCenter: summary.verticalCenter
					glyph: Icons.g("x")
					font.pixelSize: 14
					font.weight: Font.Normal
					color: closeHover.hovered ? Theme.fg : Theme.fgMuted

					HoverHandler {
						id: closeHover
					}

					MouseArea {
						anchors.fill: parent
						anchors.margins: -6
						cursorShape: Qt.PointingHandCursor
						onClicked: root.notification?.dismiss()
					}
				}
			}

			Text {
				width: parent.width
				visible: text !== ""
				text: root.notification?.body ?? ""
				textFormat: Text.StyledText
				wrapMode: Text.Wrap
				maximumLineCount: root.popup ? 4 : 3
				elide: Text.ElideRight
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 12
				lineHeight: 1.1
			}

			Text {
				width: parent.width
				horizontalAlignment: Text.AlignRight
				text: root.notification?.appName ?? ""
				visible: text !== ""
				color: Qt.alpha(Theme.fgMuted, 0.8)
				font.family: Theme.fontSans
				font.pixelSize: 11
			}

			Row {
				visible: root.buttons.length > 0
				spacing: 6
				topPadding: 4

				Repeater {
					model: root.buttons

					delegate: Rectangle {
						id: button

						required property NotificationAction modelData

						width: label.implicitWidth + 24
						height: 26
						radius: 13
						color: buttonHover.hovered ? Theme.primary : Qt.alpha(Theme.overlay, 0.9)

						Text {
							id: label

							anchors.centerIn: parent
							text: button.modelData.text
							color: buttonHover.hovered ? Theme.onPrimary : Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 12
							font.weight: Font.Medium
						}

						HoverHandler {
							id: buttonHover
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								button.modelData.invoke();
								root.finished();
							}
						}
					}
				}
			}
		}
	}
}
