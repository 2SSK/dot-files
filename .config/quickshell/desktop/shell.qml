//@ pragma NativeTextRendering
// The desktop shell (qs -c desktop): one bar per screen, which grows into the OSD and the power menu.
// The pragma above uses fontconfig hinting; Qt Quick's distance-field glyphs look soft at bar sizes.
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
	// A saved file doesn't reload the running shell (a half-written change once hung it, and a reload
	// while locked crashes it): desktop-reload checks that the config loads, then restarts the shell
	Binding {
		target: Quickshell
		property: "watchFiles"
		value: false
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

	// The panels: on sway built in the background at startup and then shown and hidden, so opening is
	// instant; on i3 made for each opening (a window shown again would go through i3's rules again)
	LazyLoader {
		activeAsync: Config.wayland || Panel.controlOpen

		ControlCenter {}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.clipboardOpen

		ClipboardWindow {}
	}

	// the lock screen on Wayland (on X11 i3lock locks)
	LazyLoader {
		active: Config.wayland

		LockScreen {}
	}

	PolkitAgent {
		id: polkit

		onIsActiveChanged: Panel.authOpen = isActive
	}

	LazyLoader {
		active: Panel.authOpen

		AuthWindow {
			agent: polkit
		}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.captureOpen

		CaptureWindow {}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.launcherOpen

		LauncherWindow {}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.wallpaperOpen

		WallpaperWindow {}
	}

	LazyLoader {
		active: Panel.settingsOpen

		SettingsWindow {
			visible: true
		}
	}

	Ipc {}
}
