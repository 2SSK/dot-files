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

	// The panels: on sway built in the background at startup and then shown and hidden, so opening is
	// instant; on i3 made for each opening (a window shown again would go through i3's rules again)
	LazyLoader {
		activeAsync: Config.wayland || Panel.controlShown

		ControlCenter {
			visible: Panel.controlShown
		}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.clipboardShown

		ClipboardWindow {
			visible: Panel.clipboardShown
		}
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
			visible: true
			agent: polkit
		}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.captureShown

		CaptureWindow {
			visible: Panel.captureShown
		}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.launcherShown

		LauncherWindow {
			visible: Panel.launcherShown
		}
	}

	LazyLoader {
		activeAsync: Config.wayland || Panel.wallpaperShown

		WallpaperWindow {
			visible: Panel.wallpaperShown
		}
	}

	LazyLoader {
		active: Panel.settingsOpen

		SettingsWindow {
			visible: true
		}
	}

	Ipc {}
}
