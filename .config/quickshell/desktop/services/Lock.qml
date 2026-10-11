pragma Singleton

import QtQuick
import Quickshell

// The session lock on Wayland (on X11 i3lock locks); if the shell stops, the compositor keeps the
// screen locked. lock() fades the desktop to black first, unlock() fades the lock screen out first.
Singleton {
	id: root

	property bool locked: false // the session lock held (LockScreen keeps it across a reload)
	property bool secure: false // the compositor confirmed it: the screen is covered
	property bool curtain: false // the desktop fading to black, just before locking
	property bool leaving: false // the lock screen fading out, just before unlocking

	function lock(): void {
		if (locked || curtain)
			return;
		curtain = true;
		dark.restart();
	}

	function unlock(): void {
		if (!locked || leaving)
			return;
		leaving = true;
		away.restart();
	}

	onSecureChanged: if (secure) curtain = false // under the lock now, and gone once it lifts

	Timer {
		id: dark

		interval: 220 // the curtain's fade
		onTriggered: root.locked = true
	}

	Timer {
		id: away

		interval: 200 // the lock screen's fade out
		onTriggered: {
			root.locked = false;
			root.leaving = false;
		}
	}
}
