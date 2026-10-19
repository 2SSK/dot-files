pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs
import qs.services
import qs.widgets
import "../Panchang.js" as Panchang

// The lock screen on Wayland, on every screen: the wallpaper blurred, a clock and the date, and a
// password field checked through PAM (lock/pam/lock).
Scope {
	id: root

	property string password: ""
	property string error: ""
	property bool checking: pam.active

	function submit(): void {
		if (!password || pam.active)
			return;
		error = "";
		pam.start();
	}

	// outside the lock, which takes only its surfaces
	PamContext {
		id: pam

		configDirectory: Quickshell.shellDir + "/lock/pam"
		config: "lock"
		onPamMessage: if (responseRequired) respond(root.password)
		onCompleted: result => {
			if (result === PamResult.Success) {
				root.password = "";
				Lock.unlock();
			} else {
				root.password = "";
				root.error = "Wrong password";
			}
		}
		onError: root.error = "Couldn't check the password"
	}

	// the picture itself, not the link to it: images are cached by their address, and the link's
	// would keep showing the wallpaper before last
	readonly property string wallpaperSource: Wallpaper.current ? "file://" + Wallpaper.current : ""

	// the wallpaper, decoded before any lock (and kept), so the lock's own copy is ready on its first
	// frame rather than popping in a moment after
	Image {
		visible: false
		source: root.wallpaperSource
		sourceSize.width: 1280
		asynchronous: true
	}

	// The lock outlives a reload of the shell (a config edit reloads it): a reload while locked takes
	// the lock straight back, rather than leaving the compositor's red "locker gone" screen
	PersistentProperties {
		id: kept

		reloadableId: "lockscreen"
		property bool locked: false
	}

	Component.onCompleted: if (kept.locked) Lock.locked = true // and the rest of the shell knows

	Connections {
		target: Lock

		function onLockedChanged(): void {
			kept.locked = Lock.locked;
		}
	}

	LazyLoader {
		active: Lock.curtain

		Variants {
			model: Quickshell.screens

			PanelWindow {
				required property ShellScreen modelData

				screen: modelData
				anchors {
					top: true
					bottom: true
					left: true
					right: true
				}
				exclusionMode: ExclusionMode.Ignore
				WlrLayershell.layer: WlrLayer.Overlay
				WlrLayershell.namespace: "desktop-curtain"
				color: "transparent"
				mask: Region {} // nothing to click

				Rectangle {
					anchors.fill: parent
					color: "black"

					NumberAnimation on opacity {
						from: 0
						to: 1
						duration: Theme.normal
						easing.type: Theme.curve
					}
				}
			}
		}
	}

	WlSessionLock {
		// locked from its first moment after a reload (it takes the held lock over as it's made: made
		// unlocked, it would unlock the screen)
		locked: Lock.locked || kept.locked
		onSecureChanged: Lock.secure = secure

		WlSessionLockSurface {
			id: surface

			color: "black" // as the curtain before it and the compositor's blank frame between

			SystemClock {
				id: clock

				precision: SystemClock.Minutes
			}

			Item {
				id: scene

				property bool shown: false

				anchors.fill: parent
				opacity: shown && !Lock.leaving && !Lock.dozing ? 1 : 0
				Component.onCompleted: shown = true

				Behavior on opacity {
					NumberAnimation {
						duration: Lock.dozing ? Theme.slow : Theme.normal
						easing.type: Theme.curve
					}
				}

				Image {
					id: wallpaper

					anchors.fill: parent
					source: root.wallpaperSource
					fillMode: Image.PreserveAspectCrop
					sourceSize.width: 1280
					asynchronous: true
					visible: false
				}

				// the lock fades in over the theme's colour: no blink from a picture or text popping in
				MultiEffect {
					anchors.fill: parent
					source: wallpaper
					blurEnabled: true
					blur: 1
					blurMax: 64
					opacity: wallpaper.status === Image.Ready ? 1 : 0

					Behavior on opacity {
						NumberAnimation {
							duration: Theme.slow
							easing.type: Theme.curve
						}
					}
				}

				Rectangle {
					anchors.fill: parent
					color: Qt.alpha(Theme.bg, 0.55)
				}

				Column {
					anchors.centerIn: parent
					anchors.verticalCenterOffset: -40
					spacing: 10

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Qt.formatTime(clock.date, "hh:mm AP").slice(0, 5) // 12-hour, as the bar (03:21)
						font.family: "Inter Display"
						font.weight: Font.Light
						font.pixelSize: Theme.px(128)
					}

					// राम राम in the morning, का हाल बा? after; the date in Hindi, and the month and its
					// season as Bihar counts them (Panchang.js)
					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Panchang.greeting(clock.date)
						color: Qt.alpha(Theme.fg, 0.9)
						font.pixelSize: Theme.px(30)
						font.weight: Font.Medium
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: `${Panchang.hindiDate(clock.date)}  ·  ${Panchang.season(clock.date)}`
						color: Qt.alpha(Theme.fg, 0.7)
						font.pixelSize: Theme.px(20)
					}

					Item {
						width: 1
						height: 40
					}

					Rectangle {
						id: field

						anchors.horizontalCenter: parent.horizontalCenter
						width: 300
						height: 46
						radius: height / 2
						color: Qt.alpha(Theme.surface, 0.6)
						border.width: 1
						border.color: root.error ? Theme.error : input.activeFocus && root.password ? Qt.alpha(Theme.primary, 0.8) : Qt.alpha(Theme.fg, 0.15)

						TextInput {
							id: input

							anchors.fill: parent
							anchors.leftMargin: 20
							anchors.rightMargin: 20
							verticalAlignment: TextInput.AlignVCenter
							horizontalAlignment: TextInput.AlignHCenter
							echoMode: TextInput.Password
							passwordCharacter: "•"
							color: Theme.fg
							font.family: Theme.fontSans
							font.hintingPreference: Theme.hinting
							font.weight: Theme.textWeight
							font.pixelSize: Theme.px(18)
							font.letterSpacing: 2
							focus: true
							enabled: !root.checking
							text: root.password
							onTextEdited: {
								root.password = text;
								root.error = "";
							}
							onAccepted: root.submit()
							Keys.onEscapePressed: root.password = ""
						}

						UiText {
							anchors.centerIn: parent
							visible: !root.password
							text: root.checking ? "Checking…" : "Password"
							color: Qt.alpha(Theme.fg, 0.4)
						}

						SequentialAnimation on anchors.horizontalCenterOffset {
							id: shake

							running: false
							loops: 2
							NumberAnimation { to: -10; duration: 45 }
							NumberAnimation { to: 10; duration: 90 }
							NumberAnimation { to: 0; duration: 45 }
						}
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: root.error
						color: Theme.error
						opacity: root.error ? 1 : 0
					}
				}

				UiText {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 48
					text: "Type to unlock"
					color: Qt.alpha(Theme.fg, 0.35)
				}
			}

			Connections {
				target: root

				function onErrorChanged(): void {
					if (root.error)
						shake.start();
				}
			}
		}
	}
}
