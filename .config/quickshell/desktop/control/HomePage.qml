pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.services
import qs.widgets

// Home: a greeting with the battery, quick toggles, the power profile, the levels with the sound's
// output and input to pick, and the media player while something plays.
Column {
	id: root

	readonly property string title: "Control center"
	readonly property var actions: []
	property string picking: "" // the device list open under the levels: "out", "in" or none

	// "2h 10m", "45m"
	function duration(seconds: real): string {
		const minutes = Math.round(seconds / 60);
		return minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes}m`;
	}

	spacing: 16
	onVisibleChanged: {
		if (visible)
			Power.refresh(); // the profile chips show what TLP has now
		else
			picking = "";
	}

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	Item {
		width: parent.width
		height: greeting.implicitHeight

		Column {
			id: greeting

			spacing: 2

			UiText {
				readonly property int hour: clock.date.getHours()

				text: hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
				font.family: Theme.fontHeading
				font.pixelSize: Theme.px(20)
				font.weight: Font.DemiBold
			}

			UiText {
				text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
				color: Theme.fgMuted
			}
		}

		// the battery: a gauge filled to its level (green while charging, red when low), how full, and how
		// long it lasts or takes to fill
		Row {
			id: battery

			readonly property real remaining: Battery.charging ? Battery.device?.timeToFull ?? 0 : Battery.device?.timeToEmpty ?? 0
			readonly property bool low: !Battery.charging && Battery.percent <= Battery.threshold
			readonly property color tint: low ? Theme.error : Battery.charging ? Theme.success : Theme.fg

			visible: Battery.present
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 12

			Column {
				anchors.verticalCenter: parent.verticalCenter
				spacing: 2

				UiText {
					anchors.right: parent.right
					text: Math.round(Battery.percent) + "%"
					color: battery.low ? Theme.error : Theme.fg
					font.family: Theme.fontHeading
					font.pixelSize: Theme.px(17)
					font.weight: Font.DemiBold
					font.features: ({ tnum: 1 })
				}

				UiText {
					anchors.right: parent.right
					visible: text !== ""
					text: Battery.device?.state === UPowerDeviceState.FullyCharged ? "Full" : battery.remaining > 60 ? root.duration(battery.remaining) + (Battery.charging ? " to full" : " left") : Battery.charging ? "Charging" : ""
					color: Theme.fgMuted
					font.pixelSize: Theme.textCaption
				}
			}

			// the gauge: a body outlined, filled from the left, and the terminal's nub
			Row {
				anchors.verticalCenter: parent.verticalCenter
				spacing: 2

				Rectangle {
					width: 34
					height: 18
					radius: Theme.radiusSmall
					color: "transparent"
					border.width: 2
					border.color: Qt.alpha(battery.tint, 0.55)

					Rectangle {
						x: 3
						y: 3
						width: Math.max(2, (parent.width - 6) * Math.min(1, Battery.percent / 100))
						height: parent.height - 6
						radius: 2
						color: battery.tint
					}

					Glyph {
						visible: Battery.charging
						anchors.centerIn: parent
						glyph: Icons.g("bolt")
						color: Theme.bg
						font.pixelSize: 11
					}
				}

				Rectangle {
					anchors.verticalCenter: parent.verticalCenter
					width: 3
					height: 7
					radius: 1.5
					color: Qt.alpha(battery.tint, 0.55)
				}
			}
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
			glyph: Connectivity.airplane ? Icons.g("plane") : Icons.g("plane-off")
			label: "Airplane mode"
			detail: Connectivity.airplane ? "Wi-Fi and Bluetooth off" : "Off"
			on: Connectivity.airplane
			available: Connectivity.wifiAvailable || Connectivity.bluetoothAvailable
			onClicked: Connectivity.toggleAirplane()
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
			glyph: Icons.g("coffee")
			label: "Keep awake"
			detail: Idle.awake ? "No dimming or locking" : "Off"
			on: Idle.awake
			onClicked: Idle.awake = !Idle.awake
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
			glyph: Icons.g("video")
			label: "Screen recording"
			detail: Recorder.recording ? "Recording" : "Off"
			on: Recorder.recording
			onClicked: Recorder.toggle()
		}
	}

	// TLP's profile holds until the next plug or unplug resets it to balanced or the power saver
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

	// the sound's devices, where a click sends it: PipeWire's short names (Speaker, HDMI 1, a headset's)
	component Picker: Column {
		id: picker

		required property string kind // "out" or "in"
		readonly property bool open: root.picking === kind
		readonly property PwNode current: kind === "out" ? Audio.sink : Audio.source
		readonly property var nodes: Array.from(Pipewire.nodes.values).filter(n => n.audio && !n.isStream && n.isSink === (kind === "out")).sort((a, b) => nameOf(a).localeCompare(nameOf(b)))

		function nameOf(node: PwNode): string {
			return node?.nickname || node?.description || node?.name || "None";
		}

		width: parent.width
		spacing: 4

		Rectangle {
			width: parent.width
			height: 30
			radius: Theme.radiusSmall
			color: pickHover.hovered ? Qt.alpha(Theme.overlay, 0.9) : "transparent"

			HoverHandler {
				id: pickHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: root.picking = picker.open ? "" : picker.kind
			}

			UiText {
				x: 38
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width - 70
				text: (picker.kind === "out" ? "Output: " : "Input: ") + picker.nameOf(picker.current)
				elide: Text.ElideRight
				color: Theme.fgMuted
				font.pixelSize: Theme.textLabel
			}

			Glyph {
				anchors.right: parent.right
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g("chevron-down")
				rotation: picker.open ? 180 : 0
				color: Theme.fgMuted
				font.pixelSize: 14

				Behavior on rotation {
					NumberAnimation {
						duration: Theme.quick
						easing.type: Theme.curve
					}
				}
			}
		}

		Repeater {
			model: picker.open ? picker.nodes : []

			delegate: Rectangle {
				id: option

				required property PwNode modelData
				readonly property bool chosen: modelData === picker.current

				x: 30
				width: picker.width - 30
				height: 34
				radius: Theme.radiusSmall
				color: chosen ? Qt.alpha(Theme.primary, 0.16) : optionHover.hovered ? Qt.alpha(Theme.overlay, 0.9) : "transparent"

				HoverHandler {
					id: optionHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (picker.kind === "out")
							Pipewire.preferredDefaultAudioSink = option.modelData;
						else
							Pipewire.preferredDefaultAudioSource = option.modelData;
						root.picking = "";
					}
				}

				Glyph {
					x: 10
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g(picker.kind === "in" ? "microphone" : /hdmi|displayport/i.test(option.modelData?.description ?? "") ? "device-desktop" : /head|bluez/i.test((option.modelData?.name ?? "") + (option.modelData?.description ?? "")) ? "headphones" : "device-speaker")
					color: option.chosen ? Theme.primary : Theme.fgMuted
					font.pixelSize: 15
				}

				UiText {
					x: 36
					anchors.verticalCenter: parent.verticalCenter
					width: parent.width - 70
					text: picker.nameOf(option.modelData)
					elide: Text.ElideRight
					color: option.chosen ? Theme.primary : Theme.fg
					font.pixelSize: Theme.textLabel
				}

				Glyph {
					visible: option.chosen
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g("check")
					color: Theme.primary
					font.pixelSize: 14
				}
			}
		}
	}

	Rectangle {
		width: parent.width
		height: levels.implicitHeight + 24
		radius: Theme.radiusCard
		color: Qt.alpha(Theme.surface, 0.8)

		Column {
			id: levels

			x: 12
			y: 12
			width: parent.width - 24
			spacing: 4

			Level {
				width: parent.width
				glyph: Audio.muted ? Icons.g("volume-off") : Icons.g("volume")
				value: Audio.volume
				muted: Audio.muted
				onMoved: value => Audio.setVolume(value)
				onIconClicked: Audio.toggleMute()
			}

			Picker {
				kind: "out"
			}

			Level {
				width: parent.width
				glyph: Audio.micMuted ? Icons.g("microphone-off") : Icons.g("microphone")
				value: Audio.micVolume
				muted: Audio.micMuted
				onMoved: value => Audio.setMic(value)
				onIconClicked: Audio.toggleMic()
			}

			Picker {
				kind: "in"
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

	// only while something plays (an empty card was just a big blank)
	MediaCard {
		visible: Media.players.length > 0
		width: parent.width
	}
}
