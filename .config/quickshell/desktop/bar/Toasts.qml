pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.I3
import Quickshell.Services.Notifications
import qs
import qs.services

// Notification popups, stacked at the top right under the OSD card, on the focused screen. Each
// leaves after its timeout (5 s unless the app says otherwise), not while hovered; critical ones
// stay until closed. Leaving the popups keeps them in the history.
PopupWindow {
	id: root

	required property PanelWindow bar

	readonly property bool focused: I3.focusedMonitor?.name === bar.screen?.name
	readonly property int pad: 28
	readonly property real below: Panel.osdShown ? 84 : 0 // room for the OSD card above

	anchor.window: bar
	anchor.rect.x: bar.width - implicitWidth
	anchor.rect.y: (Config.position === "top" ? bar.height : 0) - 14 + below
	implicitWidth: 360 + 2 * pad
	implicitHeight: Math.max(1, stack.implicitHeight) + 2 * pad
	// not over the control center, which lists them anyway
	visible: focused && Notifications.popups.length > 0 && !Panel.controlOpen
	color: "transparent"
	mask: Region {
		item: stack
		radius: 16 // the cards' corners; picom blurs inside this shape
	}

	Column {
		id: stack

		x: root.pad
		y: root.pad
		spacing: 10

		Repeater {
			model: Notifications.popups

			delegate: Item {
				id: toast

				required property Notification modelData
				readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

				width: card.implicitWidth
				height: card.implicitHeight

				RectangularShadow {
					anchors.fill: card
					radius: card.radius
					blur: 22
					offset.y: 4
					color: Qt.alpha("black", 0.4)
				}

				NotificationCard {
					id: card

					anchors.fill: parent
					notification: toast.modelData
					popup: true
					onFinished: Notifications.hide(toast.modelData)
				}

				Timer {
					interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout : Config.notifications.timeout
					running: !toast.critical && toast.modelData.expireTimeout !== 0 && !card.hovered
					onTriggered: Notifications.hide(toast.modelData)
				}
			}
		}
	}
}
