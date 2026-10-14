pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.widgets
import qs.services

// Notification popups at the top right under the OSD card, on the focused screen. Each leaves after
// its timeout unless hovered, critical ones stay until closed, and all stay in the history.
PopupWindow {
	id: root

	required property PanelWindow bar

	readonly property bool focused: WindowManager.focusedOutput === bar.screen?.name
	readonly property int pad: 28
	readonly property real below: Panel.osdShown ? 84 : 0 // room for the OSD card above

	anchor.window: bar
	anchor.rect.x: bar.width - implicitWidth
	anchor.rect.y: (Config.position === "top" ? bar.height : 0) - 14 + below
	implicitWidth: 360 + 2 * pad
	// a fixed height, room for the four it keeps: a popup that grows once shown keeps showing its old
	// frame (a second toast never appeared); the mask lets clicks through around the cards
	implicitHeight: 640 + 2 * pad
	// not over the control center's notifications, which lists them anyway
	visible: focused && Notifications.popups.length > 0 && !Panel.showing("notifications")
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

		// the rest glide up into a gap a toast leaves
		move: Transition {
			NumberAnimation {
				properties: "y"
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Repeater {
			// a ScriptModel keeps the toasts already up (and their timers) when another arrives
			model: ScriptModel {
				values: Notifications.popups
			}

			delegate: Item {
				id: toast

				required property Notification modelData
				readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
				// glides in from the right as it arrives, and out before it goes
				property real shown: 0

				function leave(): void {
					if (gone.running)
						return;
					shown = 0;
					gone.start();
				}

				width: card.implicitWidth
				height: card.implicitHeight
				opacity: shown
				Component.onCompleted: shown = 1

				Behavior on shown {
					NumberAnimation {
						duration: Theme.normal
						easing.type: Theme.curve
					}
				}

				Timer {
					id: gone

					interval: Theme.normal
					onTriggered: Notifications.hide(toast.modelData)
				}

				Shadow {
					anchors.fill: card
					anchors.leftMargin: card.anchors.leftMargin
					anchors.rightMargin: card.anchors.rightMargin
					radius: card.radius
					blur: 22
					offsetY: 4
					color: Qt.alpha("black", 0.4)
				}

				NotificationCard {
					id: card

					anchors.fill: parent
					anchors.leftMargin: 24 * (1 - toast.shown)
					anchors.rightMargin: -24 * (1 - toast.shown)
					notification: toast.modelData
					popup: true
					onFinished: toast.leave()
				}

				Timer {
					// Quickshell 0.3 passes milliseconds though its docs say seconds; under 1000 is taken as seconds
					readonly property real given: toast.modelData.expireTimeout

					interval: given > 0 ? (given < 1000 ? given * 1000 : given) : Config.notifications.timeout
					running: !toast.critical && toast.modelData.expireTimeout !== 0 && !card.hovered
					onTriggered: toast.leave()
				}
			}
		}
	}
}
