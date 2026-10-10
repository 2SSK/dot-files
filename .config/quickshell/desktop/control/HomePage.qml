import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Home: a greeting, quick toggles, the power profile, the levels and the media player.
Column {
	id: root

	readonly property string title: "Control center"
	readonly property var actions: []

	spacing: 16
	Component.onCompleted: Power.refresh() // the profile chips show what TLP has now

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
			glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off")
			label: "Wi-Fi"
			detail: !Connectivity.wifiAvailable ? "Not available" : !Connectivity.wifi ? "Off" : Connectivity.network || "Not connected"
			on: Connectivity.wifi
			available: Connectivity.wifiAvailable
			onClicked: Connectivity.toggleWifi()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off")
			label: "Bluetooth"
			detail: !Connectivity.bluetoothAvailable ? "Not available" : !Connectivity.bluetooth ? "Off" : Connectivity.device || "On"
			on: Connectivity.bluetooth
			available: Connectivity.bluetoothAvailable
			onClicked: Connectivity.toggleBluetooth()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Notifications.dnd ? Icons.g("bell-off") : Icons.g("bell")
			label: "Do Not Disturb"
			detail: Notifications.dnd ? "On" : "Off"
			on: Notifications.dnd
			onClicked: Notifications.dnd = !Notifications.dnd
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Audio.micMuted ? Icons.g("microphone-off") : Icons.g("microphone")
			label: "Microphone"
			detail: Audio.micMuted ? "Muted" : "On"
			on: !Audio.micMuted
			onClicked: Audio.toggleMic()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Recorder.recording ? Icons.g("video") : Icons.g("video")
			label: "Screen recording"
			detail: Recorder.recording ? "Recording" : "Off"
			on: Recorder.recording
			onClicked: Recorder.toggle()
		}

		Tile {
			width: (parent.width - 10) / 2
			glyph: Icons.g("moon")
			label: "Night light"
			detail: !NightLight.available ? "Not installed" : NightLight.active ? NightLight.temperature + " K" : NightLight.scheduled ? "Off till morning" : Config.nightLight.schedule ? "From " + Config.nightLight.from : "Off"
			on: NightLight.active
			available: NightLight.available
			onClicked: NightLight.toggle()
		}
	}

	// TLP's power profile, for now: the next plug or unplug goes back to balanced on the charger,
	// the power saver on battery
	Row {
		visible: Power.available
		width: parent.width
		spacing: 8

		Repeater {
			model: [
				{ name: "power-saver", label: "Quiet", glyph: "battery-4" },
				{ name: "balanced", label: "Balanced", glyph: "adjustments-horizontal" },
				{ name: "performance", label: "Performance", glyph: "flame" }
			]

			delegate: Chip {
				required property var modelData

				width: (root.width - 16) / 3
				glyph: Icons.g(modelData.glyph)
				label: modelData.label
				on: Power.profile === modelData.name
				onClicked: Power.setProfile(modelData.name)
			}
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
				glyph: Audio.muted ? Icons.g("volume-off") : Icons.g("volume")
				value: Audio.volume
				muted: Audio.muted
				onMoved: value => Audio.setVolume(value)
				onIconClicked: Audio.toggleMute()
			}

			Level {
				width: parent.width
				glyph: Audio.micMuted ? Icons.g("microphone-off") : Icons.g("microphone")
				value: Audio.micVolume
				muted: Audio.micMuted
				onMoved: value => Audio.setMic(value)
				onIconClicked: Audio.toggleMic()
			}

			Level {
				visible: Brightness.available
				width: parent.width
				glyph: Icons.g("brightness-up")
				value: Brightness.value
				onMoved: value => Brightness.set(value)
			}
		}
	}

	MediaCard {
		width: parent.width
	}
}
