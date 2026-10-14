pragma Singleton

import QtQuick
import Quickshell
import qs

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

	// Lock & Suspend: on sway the lock screen shows, fades to black, then the laptop sleeps, and it
	// fades back in on waking; on i3, i3lock (run before sleep) can't fade, so it just sleeps
	function suspend(): void {
		if (!Config.wayland)
			return Quickshell.execDetached(["systemctl", "suspend"]);
		sleepy = true;
		if (secure)
			seen.restart();
		else
			lock();
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
			seen.restart();
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

	// the lock screen shown a moment, then it dozes off: the fade to black, then sleep
	Timer {
		id: seen

		interval: 700
		onTriggered: {
			root.sleepy = false;
			root.dozing = true;
			asleep.restart();
		}
	}

	Timer {
		id: asleep

		interval: 700
		onTriggered: {
			Quickshell.execDetached(["systemctl", "suspend"]);
			wake.since = wake.last = Date.now();
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
