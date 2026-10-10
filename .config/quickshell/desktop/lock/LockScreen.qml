pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs
import qs.services

// The lock screen on Wayland, on every screen: the wallpaper blurred and dimmed, a large light
// clock (12-hour, as the bar) and the date, a password field as a quiet pill of dots, a hint at the
// bottom. Enter checks the password (PAM, lock/pam/lock); a wrong one shakes the field and says so.
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

	// beside the lock: the lock itself takes only its surfaces
	PamContext {
		id: pam

		configDirectory: Quickshell.shellDir + "/lock/pam"
		config: "lock"
		onPamMessage: if (responseRequired) respond(root.password)
		onCompleted: result => {
			if (result === PamResult.Success) {
				root.password = "";
				Lock.locked = false;
			} else {
				root.password = "";
				root.error = "Wrong password";
			}
		}
		onError: root.error = "Couldn't check the password"
	}

	WlSessionLock {
		locked: Lock.locked
		onSecureChanged: Lock.secure = secure

		WlSessionLockSurface {
			id: surface

			color: Theme.bg

			SystemClock {
				id: clock

				precision: SystemClock.Minutes // the clock shows hh:mm
			}

			Image {
				id: wallpaper

				anchors.fill: parent
				source: "file://" + (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/wallpaper"
				fillMode: Image.PreserveAspectCrop
				sourceSize.width: 1280
				asynchronous: true
				visible: false
			}

			MultiEffect {
				anchors.fill: parent
				source: wallpaper
				blurEnabled: true
				blur: 1
				blurMax: 64
			}

			Rectangle {
				anchors.fill: parent
				color: Qt.alpha(Theme.bg, 0.55)
			}

			Column {
				anchors.centerIn: parent
				anchors.verticalCenterOffset: -40
				spacing: 10

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: Qt.formatTime(clock.date, "hh:mm AP").slice(0, 5) // 12-hour, as the bar (03:21)
					color: Theme.fg
					font.family: "Inter Display"
					font.hintingPreference: Theme.hinting
					font.weight: Font.Light
					font.pixelSize: 128
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: Qt.formatDate(clock.date, "dddd, d MMMM")
					color: Qt.alpha(Theme.fg, 0.7)
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: 20
				}

				Item {
					width: 1
					height: 40
				}

				// the password, as dots in a quiet pill
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
						font.pixelSize: 18
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

					Text {
						anchors.centerIn: parent
						visible: !root.password
						text: root.checking ? "Checking…" : "Password"
						color: Qt.alpha(Theme.fg, 0.4)
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.weight: Theme.textWeight
						font.pixelSize: 14
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

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: root.error
					color: Theme.error
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: 14
					opacity: root.error ? 1 : 0
				}
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 48
				text: "Type to unlock"
				color: Qt.alpha(Theme.fg, 0.35)
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.weight: Theme.textWeight
				font.pixelSize: 14
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
