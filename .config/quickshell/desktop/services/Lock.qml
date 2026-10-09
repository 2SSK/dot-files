pragma Singleton

import QtQuick
import Quickshell

// The lock on Wayland (sway): Quickshell's session lock (LockScreen), the screen locked until your
// password unlocks it; if the shell stopped, the compositor would keep the screen locked. Locked
// by `desktop-lock` (the power menu's Lock, swayidle, before sleep) over IPC. On X11 i3lock locks.
Singleton {
	property bool locked: false
}
