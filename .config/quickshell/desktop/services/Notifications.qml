pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification daemon: apps' notifications arrive here and show as popups (Toasts). The
// history (the control center's Notifications tab) is the shell's own record of each, kept until
// you dismiss it or clear them all, and across reboots (the newest 100, two weeks): apps close
// their notifications themselves (a browser, so Teams or Slack in one, as soon as it shows; others
// mark theirs transient), and those used to vanish from the history unseen. An action button works
// while the app's notification is still open. Do Not Disturb keeps them out of the popups, except
// critical ones; they still reach the history.
//
// A history entry: { key, id, appName, appIcon, summary, body, image, urgency, time }
Singleton {
	id: root

	readonly property string file: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/notifications.json"
	property bool dnd: false
	property int unread: 0
	property var popups: [] // live notifications shown as popups now, newest first
	property var history: [] // the record, newest first
	property var live: ({}) // entry key -> its notification, while the app keeps it open
	property var keys: ({}) // a live notification's id -> its entry key
	property bool loaded: false

	// the entry's or notification's time, actions, and key
	function timeOf(n: var): real {
		return n?.time ?? history.find(e => e.key === keys[n?.id])?.time ?? Date.now();
	}

	function actionsOf(n: var): var {
		return (n?.key ? live[n.key]?.actions : n?.actions) ?? [];
	}

	function hide(notification: var): void {
		popups = popups.filter(n => n && n !== notification);
	}

	// dismissed for good: out of the history, and closed if the app still has it open
	function dismiss(n: var): void {
		const key = n?.key ?? keys[n?.id];
		live[key]?.dismiss();
		if (!n?.key)
			n?.dismiss?.();
		history = history.filter(e => e.key !== key);
	}

	function clear(): void {
		for (const n of server.trackedNotifications.values.slice())
			n.dismiss();
		history = [];
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
			const key = `${Date.now()}-${notification.id}`;
			const entry = {
				key,
				id: notification.id,
				appName: notification.appName,
				appIcon: notification.appIcon,
				summary: notification.summary,
				body: notification.body,
				image: notification.image,
				urgency: notification.urgency,
				time: Date.now()
			};
			root.live = Object.assign({}, root.live, { [key]: notification });
			root.keys = Object.assign({}, root.keys, { [notification.id]: key });
			// a replacement (same id, newer text) takes the old entry's place
			root.history = [entry, ...root.history.filter(e => !(e.id === notification.id && root.live[e.key] === notification && e.key !== key))].slice(0, 100);
			root.unread++;
			if (!root.dnd || notification.urgency === NotificationUrgency.Critical)
				root.popups = [notification, ...root.popups.filter(n => n)].slice(0, 4);
			notification.closed.connect(() => {
				root.hide(notification);
				const live = Object.assign({}, root.live);
				delete live[key];
				root.live = live; // the entry stays
			});
		}
	}

	// the record on disk, a moment after it changes: what stays meaningful after a restart (an
	// app's image exists only while its notification is open; the icon stands in)
	onHistoryChanged: if (loaded) saveLater.restart()

	Timer {
		id: saveLater

		interval: 1000
		onTriggered: {
			saved.entries = root.history.map(e => Object.assign({}, e, { image: /^(file:|\/)/.test(e.image ?? "") ? e.image : "" }));
			store.writeAdapter();
		}
	}

	FileView {
		id: store

		path: root.file
		printErrors: false
		onLoaded: {
			const fortnight = Date.now() - 14 * 86400000;
			root.history = [...root.history, ...saved.entries.filter(e => e?.key && e.time >= fortnight)].slice(0, 100);
			root.loaded = true;
		}
		onLoadFailed: root.loaded = true

		JsonAdapter {
			id: saved

			property var entries: []
		}
	}
}
