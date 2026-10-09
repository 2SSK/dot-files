pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.bar
import qs.services
import qs.settings
import qs.widgets

// The notification history, newest first, filtered by day; Do Not Disturb and Clear at the top.
Column {
	id: root

	readonly property string title: "Notifications"
	readonly property var actions: [
		{ glyph: Notifications.dnd ? Icons.g("bell-slash") : Icons.g("bell"), on: Notifications.dnd, act: () => Notifications.dnd = !Notifications.dnd },
		{ glyph: Icons.g("trash"), on: false, act: () => Notifications.clear(), show: Notifications.history.length > 0 }
	]
	property string filter: "all"

	// days since midnight today when it arrived: 0 today, 1 yesterday, ...
	function age(notification: Notification): int {
		const midnight = new Date().setHours(0, 0, 0, 0);
		const when = Notifications.received[notification.id] ?? Date.now();
		return when >= midnight ? 0 : Math.ceil((midnight - when) / 86400000);
	}

	readonly property var shown: Notifications.history.filter(n => n && (filter === "all" || (filter === "today" && age(n) === 0) || (filter === "yesterday" && age(n) === 1) || (filter === "older" && age(n) > 1)))

	spacing: 14

	Choice {
		width: parent.width
		options: [{ value: "all", label: "All" }, { value: "today", label: "Today" }, { value: "yesterday", label: "Yesterday" }, { value: "older", label: "Older" }]
		value: root.filter
		onPicked: value => root.filter = value
	}

	Column {
		width: parent.width
		spacing: 8

		Repeater {
			model: root.shown

			delegate: NotificationCard {
				required property Notification modelData

				width: parent.width
				notification: modelData
				onFinished: modelData.dismiss()
			}
		}
	}

	Rectangle {
		visible: root.shown.length === 0
		width: parent.width
		height: 120
		radius: 14
		color: Qt.alpha(Theme.surface, 0.6)

		Column {
			anchors.centerIn: parent
			spacing: 8

			Glyph {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Notifications.dnd ? Icons.g("bell-slash") : Icons.g("bell")
				font.pixelSize: 26
				font.weight: Font.Normal
				color: Theme.fgMuted
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: root.filter === "all" ? "No notifications" : "Nothing from " + (root.filter === "older" ? "before yesterday" : root.filter)
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 13
			}
		}
	}
}
