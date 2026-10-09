import QtQuick
import QtQuick.Effects

// The login screen. Colours, fonts and the wallpaper come from theme.conf (config.*), which
// packages/system.sh sddm renders from the desktop theme; sddm, userModel and sessionModel are
// provided by sddm.
Rectangle {
	id: root

	property int session: sessionModel.lastIndex
	// The last user, else the first one (a fresh install has no last user yet)
	readonly property string user: userModel.lastUser || (users.count > 0 ? users.itemAt(0).name : "")

	function login() {
		sddm.login(root.user, password.text, root.session);
	}

	color: config.bg
	Keys.onEscapePressed: sessionMenu.open = false

	Image {
		id: wallpaper

		anchors.fill: parent
		source: config.background
		fillMode: Image.PreserveAspectCrop
		visible: false
	}

	MultiEffect {
		anchors.fill: parent
		source: wallpaper
		blurEnabled: true
		blur: 0.7
		blurMax: 64
	}

	Rectangle {
		anchors.fill: parent
		color: config.bg
		opacity: 0.45
	}

	// A click anywhere else closes the session menu
	MouseArea {
		anchors.fill: parent
		enabled: sessionMenu.open
		onClicked: sessionMenu.open = false
	}

	Column {
		anchors.horizontalCenter: parent.horizontalCenter
		y: parent.height * 0.18
		spacing: 4

		Text {
			id: time

			anchors.horizontalCenter: parent.horizontalCenter
			color: config.fg
			font.family: config.font
			font.pixelSize: 96
			font.weight: Font.Light
		}

		Text {
			id: date

			anchors.horizontalCenter: parent.horizontalCenter
			color: config.fgMuted
			font.family: config.font
			font.pixelSize: 20
		}

		Timer {
			interval: 1000
			running: true
			repeat: true
			triggeredOnStart: true
			onTriggered: {
				const now = new Date();
				time.text = Qt.formatTime(now, "HH:mm");
				date.text = Qt.formatDate(now, "dddd, d MMMM");
			}
		}
	}

	Column {
		anchors.horizontalCenter: parent.horizontalCenter
		y: parent.height * 0.58
		spacing: 14

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.user
			color: config.fg
			font.family: config.font
			font.pixelSize: 18
			font.weight: Font.Medium
		}

		Rectangle {
			id: field

			width: 320
			height: 44
			radius: 14
			color: Qt.alpha(config.surface, 0.85)
			border.width: 1
			border.color: error.visible ? config.error : password.activeFocus ? config.primary : config.border

			TextInput {
				id: password

				anchors.fill: parent
				anchors.leftMargin: 44
				anchors.rightMargin: 44
				verticalAlignment: TextInput.AlignVCenter
				horizontalAlignment: TextInput.AlignHCenter
				echoMode: reveal.shown ? TextInput.Normal : TextInput.Password
				passwordCharacter: "•"
				color: config.fg
				font.family: config.font
				font.pixelSize: 16
				focus: true
				cursorVisible: activeFocus && text.length > 0
				onTextEdited: error.visible = false
				Keys.onReturnPressed: root.login()
				Keys.onEnterPressed: root.login()
			}

			Text {
				anchors.centerIn: parent
				visible: password.text.length === 0
				text: "Password"
				color: config.fgMuted
				font.family: config.font
				font.pixelSize: 15
			}

			// Show or hide what's typed
			Text {
				id: reveal

				property bool shown: false

				anchors.right: parent.right
				anchors.rightMargin: 14
				anchors.verticalCenter: parent.verticalCenter
				text: shown ? "󰈉" : "󰈈"
				color: revealHover.containsMouse || shown ? config.fg : config.fgMuted
				font.family: config.fontMono
				font.pixelSize: 18

				MouseArea {
					id: revealHover

					anchors.fill: parent
					anchors.margins: -6
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						reveal.shown = !reveal.shown;
						password.forceActiveFocus();
					}
				}
			}

			SequentialAnimation on anchors.horizontalCenterOffset {
				id: shake

				running: false
				loops: 2
				NumberAnimation { to: -10; duration: 50 }
				NumberAnimation { to: 10; duration: 100 }
				NumberAnimation { to: 0; duration: 50 }
			}
		}

		Text {
			id: error

			anchors.horizontalCenter: parent.horizontalCenter
			visible: false
			text: "Wrong password"
			color: config.error
			font.family: config.font
			font.pixelSize: 14
		}
	}

	// User and session names, read through hidden repeaters: the models only expose them to delegates
	Repeater {
		id: users

		model: userModel

		delegate: Item {
			required property string name
		}
	}

	Repeater {
		id: sessions

		model: sessionModel

		delegate: Item {
			required property string name
		}
	}

	// Session: its name in the bottom left; a click opens a small menu just above it
	Item {
		id: sessionButton

		anchors.left: parent.left
		anchors.bottom: parent.bottom
		anchors.margins: 32
		implicitWidth: sessionRow.implicitWidth
		implicitHeight: sessionRow.implicitHeight

		Row {
			id: sessionRow

			spacing: 6

			Text {
				text: sessions.count > 0 && sessions.itemAt(root.session) ? sessions.itemAt(root.session).name : ""
				color: sessionMenu.open || sessionHover.containsMouse ? config.fg : config.fgMuted
				font.family: config.font
				font.pixelSize: 15
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: "󰅃"
				rotation: sessionMenu.open ? 0 : 180
				color: config.fgMuted
				font.family: config.fontMono
				font.pixelSize: 12

				Behavior on rotation {
					NumberAnimation {
						duration: 200
						easing.type: Easing.OutCubic
					}
				}
			}
		}

		MouseArea {
			id: sessionHover

			anchors.fill: parent
			anchors.margins: -6
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: sessionMenu.open = !sessionMenu.open
		}
	}

	Rectangle {
		id: sessionMenu

		property bool open: false

		anchors.left: sessionButton.left
		anchors.bottom: sessionButton.top
		anchors.leftMargin: -12
		anchors.bottomMargin: open ? 12 : 4
		width: Math.max(160, choices.implicitWidth + 12)
		height: choices.implicitHeight + 12
		radius: 12
		color: Qt.alpha(config.surface, 0.9)
		border.width: 1
		border.color: config.border
		opacity: open ? 1 : 0
		visible: opacity > 0

		Behavior on opacity {
			NumberAnimation {
				duration: 180
			}
		}

		Behavior on anchors.bottomMargin {
			NumberAnimation {
				duration: 220
				easing.type: Easing.OutCubic
			}
		}

		Column {
			id: choices

			anchors.centerIn: parent

			Repeater {
				model: sessionModel

				delegate: Rectangle {
					id: choice

					required property int index
					required property string name

					readonly property bool current: index === root.session

					visible: !name.includes("debug log") // i3's extra debugging session
					width: Math.max(148, label.implicitWidth + 24)
					height: visible ? 32 : 0
					radius: 8
					color: choiceHover.containsMouse ? Qt.alpha(config.overlay, 0.6) : "transparent"

					Text {
						id: label

						anchors.left: parent.left
						anchors.leftMargin: 12
						anchors.verticalCenter: parent.verticalCenter
						text: choice.name
						color: choice.current ? config.primary : config.fg
						font.family: config.font
						font.pixelSize: 14
						font.weight: choice.current ? Font.DemiBold : Font.Normal
					}

					MouseArea {
						id: choiceHover

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.session = choice.index;
							sessionMenu.open = false;
							password.forceActiveFocus();
						}
					}
				}
			}
		}
	}

	// Power: reboot and shut down
	Row {
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: 32
		spacing: 22

		Repeater {
			model: [
				{ glyph: "󰜉", action: () => sddm.reboot() },
				{ glyph: "󰐥", action: () => sddm.powerOff() }
			]

			delegate: Text {
				required property var modelData

				text: modelData.glyph
				color: powerHover.containsMouse ? config.fg : config.fgMuted
				font.family: config.fontMono
				font.pixelSize: 22

				MouseArea {
					id: powerHover

					anchors.fill: parent
					anchors.margins: -6
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: parent.modelData.action()
				}
			}
		}
	}

	Connections {
		target: sddm

		function onLoginFailed() {
			password.text = "";
			error.visible = true;
			shake.start();
		}
	}
}
