pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs
import qs.services
import qs.widgets

// The lock screen on Wayland, on every screen: the wallpaper blurred, a clock and the date, and a
// password field checked through PAM (lock/pam/lock). Locking, the picture comes in sharp and blurs
// as it drifts a little closer, then the clock, the date and the field come in one after another;
// unlocking, the field shows a tick, they lift away and the picture sharpens back for the desktop.
Scope {
	id: root

	property string password: ""
	property string error: ""
	property bool checking: pam.active
	property bool ok: false // the password was right: the field shows a tick a moment, then it unlocks

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
				root.ok = true;
				unlocking.restart();
			} else {
				root.password = "";
				root.error = "Wrong password";
			}
		}
		onError: root.error = "Couldn't check the password"
	}

	Timer {
		id: unlocking

		interval: 260 // the tick seen
		onTriggered: Lock.unlock()
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
			if (Lock.locked)
				root.ok = false;
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
				// 0 to 1 as the lock comes in: the picture blurs and tints, and the rest follows it in
				property real enter: 0
				// 0 to 1 as it unlocks: the clock, date and field lift away, the picture sharpens back
				property real leave: Lock.leaving ? 1 : 0
				readonly property real veil: enter * (1 - leave)

				anchors.fill: parent
				opacity: shown && !Lock.dozing ? 1 : 0
				Component.onCompleted: {
					shown = true;
					coming.start();
				}

				Behavior on opacity {
					NumberAnimation {
						duration: Lock.dozing ? Theme.slow : Theme.normal
						easing.type: Theme.curve
					}
				}

				Behavior on leave {
					NumberAnimation {
						duration: 440
						easing.type: Theme.curve
					}
				}

				NumberAnimation {
					id: coming

					target: scene
					property: "enter"
					from: 0
					to: 1
					duration: 1100
					easing.type: Theme.curve
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
					blur: scene.veil
					blurMax: 64
					scale: 1 + 0.06 * scene.veil
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
					opacity: scene.veil
				}

				// each comes in a beat after the one above it, from a little way off, and they all
				// lift away together; `delay` is its share of the way in (0 first, larger later). An
				// inline component can't see the file's ids: the scene's progress is passed in
				component Arrives: Item {
					id: arrive

					property real enter: 0
					property real leave: 0
					property real delay: 0
					property real from: -28
					readonly property real t: Math.max(0, Math.min(1, (enter - delay) / (1 - delay)))
					// eased again: the shared progress is already an ease-out
					readonly property real eased: 1 - Math.pow(1 - t, 2)

					opacity: eased * (1 - leave)
					transform: Translate {
						y: (1 - arrive.eased) * arrive.from - 40 * arrive.leave
					}
				}

				Column {
					anchors.centerIn: parent
					anchors.verticalCenterOffset: -40
					spacing: 12

					Arrives {
						anchors.horizontalCenter: parent.horizontalCenter
						enter: scene.enter
						leave: scene.leave
						width: clockText.implicitWidth
						height: clockText.implicitHeight
						delay: 0.12

						UiText {
							id: clockText

							text: Qt.formatTime(clock.date, "HH:mm")
							color: "white"
							font.family: Theme.fontHeading
							font.weight: Font.Medium
							font.pixelSize: 112
							font.letterSpacing: -4
						}
					}

					Arrives {
						anchors.horizontalCenter: parent.horizontalCenter
						enter: scene.enter
						leave: scene.leave
						width: dateText.implicitWidth
						height: dateText.implicitHeight
						delay: 0.2
						from: -16

						UiText {
							id: dateText

							text: Qt.formatDate(clock.date, "dddd, d MMMM")
							color: Qt.alpha("white", 0.8)
							font.pixelSize: 15
							font.weight: Font.DemiBold
						}
					}

					Item {
						width: 1
						height: 40
					}

					Arrives {
						anchors.horizontalCenter: parent.horizontalCenter
						enter: scene.enter
						leave: scene.leave
						width: 280
						height: 46
						delay: 0.28
						from: 18

						// frosted: the blurred picture shows through, a little lighter, with a hairline
						// that takes the accent while you type and goes red on a wrong password
						Rectangle {
							id: field

							width: parent.width
							height: parent.height
							radius: height / 2
							color: Qt.alpha("white", input.activeFocus && root.password ? 0.16 : 0.11)
							border.width: 1
							border.color: root.error ? Theme.error : root.ok ? Theme.success : input.activeFocus && root.password ? Qt.alpha(Theme.primary, 0.85) : Qt.alpha("white", 0.2)

							Behavior on color {
								enabled: !Theme.switching
								ColorAnimation {
									duration: Theme.quick
								}
							}

							Behavior on border.color {
								enabled: !Theme.switching
								ColorAnimation {
									duration: Theme.normal
								}
							}

							TextInput {
								id: input

								anchors.fill: parent
								anchors.leftMargin: 18
								anchors.rightMargin: 44
								verticalAlignment: TextInput.AlignVCenter
								horizontalAlignment: TextInput.AlignLeft
								echoMode: TextInput.Password
								passwordCharacter: "•"
								color: "white"
								font.family: Theme.fontSans
								font.hintingPreference: Theme.hinting
								font.weight: Theme.textWeight
								font.pixelSize: Theme.px(18)
								font.letterSpacing: 2
								focus: true
								enabled: !root.checking && !root.ok
								text: root.password
								onTextEdited: {
									root.password = text;
									root.error = "";
								}
								onAccepted: root.submit()
								Keys.onEscapePressed: root.password = ""
							}

							UiText {
								anchors.left: parent.left
								anchors.leftMargin: 18
								anchors.verticalCenter: parent.verticalCenter
								visible: !root.password
								text: root.checking ? "Checking…" : "Password"
								color: Qt.alpha("white", 0.6)
								font.weight: Font.DemiBold
							}

							Glyph {
								anchors.right: parent.right
								anchors.rightMargin: 16
								anchors.verticalCenter: parent.verticalCenter
								glyph: Icons.g(root.ok ? "check" : "lock")
								color: root.ok ? Theme.success : Qt.alpha("white", 0.65)
								font.pixelSize: 18
								scale: root.ok ? 1.15 : 1

								Behavior on scale {
									NumberAnimation {
										duration: Theme.normal
										easing.type: Easing.OutBack
									}
								}
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
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: root.error
						color: Theme.error
						opacity: root.error ? 1 : 0

						Behavior on opacity {
							NumberAnimation {
								duration: Theme.normal
							}
						}
					}
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
