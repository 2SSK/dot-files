pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon: apps' notifications arrive here, show as popups (Toasts) and stay in
// the history (NotificationCenter) until dismissed. Do Not Disturb keeps them out of the popups,
// except critical ones; they still reach the history.
Singleton {
	id: root

	property bool dnd: false
	property int unread: 0
	property var popups: [] // shown as popups now, newest first
	property var received: ({}) // id -> when it arrived (ms)
	readonly property var history: [...server.trackedNotifications.values].reverse() // newest first

	function hide(notification: Notification): void {
		popups = popups.filter(n => n && n !== notification);
	}

	function clear(): void {
		for (const n of server.trackedNotifications.values.slice())
			n.dismiss();
		popups = [];
		unread = 0;
	}

	NotificationServer {
		id: server

		keepOnReload: true
		persistenceSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		actionsSupported: true
		imageSupported: true

		onNotification: notification => {
			notification.tracked = true;
			root.received = Object.assign({}, root.received, { [notification.id]: Date.now() });
			root.unread++;
			if (!root.dnd || notification.urgency === NotificationUrgency.Critical)
				root.popups = [notification, ...root.popups.filter(n => n)].slice(0, 4);
			notification.closed.connect(() => root.hide(notification));
		}
	}
}
