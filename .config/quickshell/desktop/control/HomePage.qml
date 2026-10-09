import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Home: a greeting, quick toggles, the levels and the media player.
Column {
	id: root

	readonly property string title: "Control center"
	readonly property var actions: []

	spacing: 16

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	Column {
		spacing: 2

		Text {
			readonly property int hour: clock.date.getHours()

			text: hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
			color: Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 20
			font.weight: Font.DemiBold
		}

		Text {
			text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 13
		}
	}

	Grid {
		width: parent.width
		columns: 2
		columnSpacing: 10
		rowSpacing: 10

		Tile {
			width: (parent.width - 10) / 2
			glyph: Connectivity.wifi ? "\u{F05A9}" : "\u{F05AA}" // md-wifi, md-wifi-off
			label: "Wi-Fi"
			detail: !Connectivity.wifiAvailable ? "Not available" : !Connectivity.wifi ? "Off" : Connectivity.network || "Not connected"
			on: Connectivity.wifi
			available: Connectivity.wifiAvailable
			onClicked: Connectivity.toggleWifi()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Connectivity.bluetooth ? "\u{F00AF}" : "\u{F00B2}" // md-bluetooth, md-bluetooth-off
			label: "Bluetooth"
			detail: !Connectivity.bluetoothAvailable ? "Not available" : !Connectivity.bluetooth ? "Off" : Connectivity.device || "On"
			on: Connectivity.bluetooth
			available: Connectivity.bluetoothAvailable
			onClicked: Connectivity.toggleBluetooth()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Notifications.dnd ? "\u{EC08}" : "\u{EAA2}"
			label: "Do Not Disturb"
			detail: Notifications.dnd ? "On" : "Off"
			on: Notifications.dnd
			onClicked: Notifications.dnd = !Notifications.dnd
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Audio.micMuted ? "\u{F036D}" : "\u{F036C}"
			label: "Microphone"
			detail: Audio.micMuted ? "Muted" : "On"
			on: !Audio.micMuted
			onClicked: Audio.toggleMic()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Recorder.recording ? "\u{F0567}" : "\u{EAD9}"
			label: "Screen recording"
			detail: Recorder.recording ? "Recording" : "Off"
			on: Recorder.recording
			onClicked: Recorder.toggle()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: "\u{F10A9}" // md-dock-bottom, upside down for a top bar
			glyphRotation: Config.position === "top" ? 180 : 0
			label: "Bar"
			detail: Panel.barShown ? "Shown" : "Hidden"
			on: Panel.barShown
			onClicked: Panel.toggleBar()
		}
	}

	Rectangle {
		width: parent.width
		height: levels.implicitHeight + 24
		radius: 16
		color: Qt.alpha(Theme.surface, 0.8)

		Column {
			id: levels

			x: 12
			y: 12
			width: parent.width - 24
			spacing: 6

			Level {
				width: parent.width
				glyph: Audio.muted ? "\u{F0581}" : "\u{F057E}"
				value: Audio.volume
				muted: Audio.muted
				onMoved: value => Audio.setVolume(value)
				onIconClicked: Audio.toggleMute()
			}

			Level {
				width: parent.width
				glyph: Audio.micMuted ? "\u{F036D}" : "\u{F036C}"
				value: Audio.micVolume
				muted: Audio.micMuted
				onMoved: value => Audio.setMic(value)
				onIconClicked: Audio.toggleMic()
			}

			Level {
				visible: Brightness.available
				width: parent.width
				glyph: "\u{F00E0}"
				value: Brightness.value
				onMoved: value => Brightness.set(value)
			}
		}
	}

	MediaCard {
		width: parent.width
	}
}
