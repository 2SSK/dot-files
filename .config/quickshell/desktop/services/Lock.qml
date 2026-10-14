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
	property bool dozing: false // the lock screen faded to black: the laptop is going to sleep, or asleep
	property bool sleepy: false // asked to sleep: once locked, it dozes off, then suspends

	function lock(): void {
		if (leaving) { // asked again while the lock screen fades out: it stays
			away.stop();
			leaving = false;
			return;
		}
		if (locked || curtain)
			return;
		curtain = true;
		dark.restart();
	}

	// Lock & Suspend: locked, the lock screen fades to black, then the laptop sleeps; it fades back in on waking
	function suspend(): void {
		sleepy = true;
		if (secure)
			doze();
		else
			lock();
	}

	function doze(): void {
		sleepy = false;
		dozing = true;
		asleep.restart();
	}

	function unlock(): void {
		if (!locked || leaving)
			return;
		leaving = true;
		away.restart();
	}

	onSecureChanged: {
		if (!secure)
			return;
		curtain = false; // under the lock now, and gone once it lifts
		if (sleepy)
			seen.restart(); // the lock screen shown a moment, then it dozes off
	}

	Timer {
		id: dark

		interval: 220 // the curtain's fade
		onTriggered: {
			root.locked = true;
			refused.restart();
		}
	}

	// Sway confirms a lock in well under a second, and refuses it while another locker (swaylock)
	// holds the screen. A refused lock is given up, curtain and all, so the next lock() can work.
	Timer {
		id: refused

		interval: 4000
		onTriggered: {
			if (!root.locked || root.secure)
				return;
			console.warn("Lock: sway refused the session lock (another locker holds the screen)");
			root.locked = false;
			root.curtain = false;
			if (root.sleepy) { // asked to sleep: it still does (the other locker holds the screen)
				root.sleepy = false;
				Quickshell.execDetached(["systemctl", "suspend"]);
			}
		}
	}

	Timer {
		id: seen

		interval: 700
		onTriggered: root.doze()
	}

	// the fade to black, then sleep
	Timer {
		id: asleep

		interval: 700
		onTriggered: {
			Quickshell.execDetached(["systemctl", "suspend"]);
			wake.last = Date.now();
			wake.start();
		}
	}

	// awake again: the clock jumped (it doesn't tick while suspended); or sleep never came (inhibited)
	Timer {
		id: wake

		property real last: 0
		property real since: 0

		interval: 1000
		repeat: true
		onRunningChanged: if (running) since = Date.now()
		onTriggered: {
			const now = Date.now();
			if (now - last > 4000 || now - since > 15000) {
				stop();
				root.dozing = false;
			}
			last = now;
		}
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
