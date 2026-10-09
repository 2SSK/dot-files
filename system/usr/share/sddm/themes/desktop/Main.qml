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
				anchors.leftMargin: 18
				anchors.rightMargin: 18
				verticalAlignment: TextInput.AlignVCenter
				horizontalAlignment: TextInput.AlignHCenter
				echoMode: TextInput.Password
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

	Text {
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		anchors.margins: 32
		text: sessions.count > 0 && sessions.itemAt(root.session) ? sessions.itemAt(root.session).name : ""
		color: chooser.open ? config.fg : config.fgMuted
		font.family: config.font
		font.pixelSize: 15

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: chooser.open = !chooser.open
		}
	}

	// Session chooser: a translucent bar that slides down from the top; a click picks a session
	Rectangle {
		id: chooser

		property bool open: false

		width: parent.width
		height: 56
		y: open ? 0 : -height
		opacity: open ? 1 : 0
		color: Qt.alpha(config.bg, 0.35)

		Behavior on y {
			NumberAnimation {
				duration: 260
				easing.type: Easing.OutCubic
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: 200
			}
		}

		Rectangle {
			anchors.bottom: parent.bottom
			width: parent.width
			height: 1
			color: config.border
		}

		Row {
			anchors.centerIn: parent
			spacing: 8

			Repeater {
				model: sessionModel

				delegate: Rectangle {
					id: choice

					required property int index
					required property string name

					readonly property bool current: index === root.session

					visible: !name.includes("debug log") // i3's extra debugging session
					width: label.implicitWidth + 32
					height: 32
					radius: 16
					color: current ? config.primary : choiceHover.containsMouse ? Qt.alpha(config.surface, 0.8) : "transparent"

					Behavior on color {
						ColorAnimation {
							duration: 150
						}
					}

					Text {
						id: label

						anchors.centerIn: parent
						text: choice.name
						color: choice.current ? config.bg : config.fg
						font.family: config.font
						font.pixelSize: 14
						font.weight: Font.Medium
					}

					MouseArea {
						id: choiceHover

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.session = choice.index;
							chooser.open = false;
							password.forceActiveFocus();
						}
					}
				}
			}
		}
	}

	Keys.onEscapePressed: chooser.open = false

	Row {
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: 32
		spacing: 22

		Repeater {
			model: [
				{ glyph: "󰤄", action: () => sddm.suspend(), enabled: sddm.canSuspend },
				{ glyph: "󰜉", action: () => sddm.reboot(), enabled: sddm.canReboot },
				{ glyph: "󰐥", action: () => sddm.powerOff(), enabled: sddm.canPowerOff }
			]

			delegate: Text {
				required property var modelData

				visible: modelData.enabled
				text: modelData.glyph
				color: hover.containsMouse ? config.fg : config.fgMuted
				font.family: config.fontMono
				font.pixelSize: 22

				MouseArea {
					id: hover

					anchors.fill: parent
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
