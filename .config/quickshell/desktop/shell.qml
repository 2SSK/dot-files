//@ pragma NativeTextRendering
// The desktop shell (qs -c desktop): one bar per screen, which grows into the OSD and the power
// menu. Settings: Config (~/.config/desktop/shell.json); colours: Theme (the desktop theme).
// Keys reach it over IPC: qs -c desktop ipc call <target> <function> (see i3's keys.conf).
// Text is drawn with the system font rasteriser (fontconfig hinting), not Qt Quick's distance-field
// glyphs, which look soft at bar sizes: the pragma above.
import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs.bar
import qs.clipboard
import qs.wallpaper
import qs.launcher
import qs.capture
import qs.polkit
import qs.lock
import qs.control
import qs.settings
import qs
import qs.services

ShellRoot {
	// No reload while the screen is locked: a reload with the session lock held crashes Quickshell,
	// leaving the compositor's red "locker gone" screen. An edit made meanwhile applies after unlocking.
	Binding {
		target: Quickshell
		property: "watchFiles"
		value: !Lock.locked
	}

	// services that watch on their own, started with the shell
	readonly property var watchers: [Locks, Recorder, Notifications, Clipboard, Events, Alarms, Wallpaper, Windows, Battery, NightLight, Idle]

	// the wallpaper, on sway's background layer (on i3 feh draws it: desktop-wallpaper)
	Variants {
		model: Config.wayland ? Quickshell.screens : []

		Backdrop {}
	}

	Variants {
		model: Quickshell.screens

		Bar {}
	}

	LazyLoader {
		active: Panel.controlShown

		ControlCenter {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.clipboardShown

		ClipboardWindow {
			visible: true
		}
	}

	// the lock screen on Wayland (on X11 i3lock locks): `lock lock` over IPC (Ipc.qml), from desktop-lock
	LazyLoader {
		active: Config.wayland

		LockScreen {}
	}

	// the polkit agent: apps asking for admin rights (pkexec, Timeshift, ...) ask through the shell
	PolkitAgent {
		id: polkit

		onIsActiveChanged: Panel.authOpen = isActive
	}

	LazyLoader {
		active: Panel.authOpen

		AuthWindow {
			visible: true
			agent: polkit
		}
	}

	LazyLoader {
		active: Panel.captureShown

		CaptureWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.launcherShown

		LauncherWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.wallpaperShown

		WallpaperWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.settingsOpen

		SettingsWindow {
			visible: true
		}
	}

	// what keys and scripts ask for: qs -c desktop ipc call <target> <function>
	Ipc {}
}
