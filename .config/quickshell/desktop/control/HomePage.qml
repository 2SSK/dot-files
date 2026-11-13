pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.services
import qs.widgets

// Home: the connections in one card (a name opens its page), quick toggles as round-icon tiles, the
// display and the sound as thick bars with the output and input to pick, the power profile, the media
// player while something plays, and the date and battery at the foot.
Column {
	id: root

	readonly property string title: "Control center"
	readonly property var actions: []
	property string picking: "" // the device list open in the sound card: "out", "in" or none
	readonly property real half: (width - 10) / 2
	readonly property real quarter: (width - 30) / 4

	// "2h 10m", "45m"
	function duration(seconds: real): string {
		const minutes = Math.round(seconds / 60);
		return minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes}m`;
	}

	spacing: 10
	onVisibleChanged: {
		if (visible)
			Power.refresh(); // the profile shows what TLP has now
		else
			picking = "";
	}

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	// one row in the connections card: a round toggle, then its name and state (a click on those opens
	// its page)
	component Connection: Item {
		id: conn

		property string glyph
		property string label
		property string detail
		property bool on
		property bool available: true
		property string page: ""
		signal toggled

		width: parent.width
		height: 36
		opacity: available ? 1 : 0.5

		Rectangle {
			id: knob

			anchors.verticalCenter: parent.verticalCenter
			width: 32
			height: 32
			radius: 16
			color: conn.on ? Theme.primary : Qt.alpha(Theme.fg, knobHover.hovered ? 0.18 : 0.12)

			Behavior on color {
				enabled: !Theme.switching
				ColorAnimation {
					duration: Theme.normal
					easing.type: Theme.curve
				}
			}

			Glyph {
				anchors.centerIn: parent
				glyph: conn.glyph
				color: conn.on ? Theme.primaryText : Theme.fg
				font.pixelSize: 16
			}

			HoverHandler {
				id: knobHover
			}

			MouseArea {
				anchors.fill: parent
				enabled: conn.available
				cursorShape: Qt.PointingHandCursor
				onClicked: conn.toggled()
			}
		}

		Column {
			anchors.left: knob.right
			anchors.leftMargin: 10
			anchors.right: chevron.left
			anchors.verticalCenter: parent.verticalCenter

			UiText {
				width: parent.width
				text: conn.label
				elide: Text.ElideRight
				font.weight: Font.DemiBold
				font.pixelSize: Theme.textLabel
			}

			UiText {
				width: parent.width
				text: conn.detail
				elide: Text.ElideRight
				color: Theme.fgMuted
				font.pixelSize: Theme.textCaption
			}
		}

		Glyph {
			id: chevron

			visible: conn.page !== ""
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			glyph: Icons.g("chevron-right")
			color: Theme.fgMuted
			font.pixelSize: 14
		}

		MouseArea {
			visible: conn.page !== ""
			anchors.left: knob.right
			anchors.right: parent.right
			height: parent.height
			cursorShape: Qt.PointingHandCursor
			onClicked: Panel.controlPage = conn.page
		}
	}

	Row {
		spacing: 10

		Rectangle {
			width: root.half
			height: 126
			radius: Theme.radiusCard + 4
			color: Qt.alpha(Theme.surface, 0.62)

			Column {
				x: 12
				width: parent.width - 24
				anchors.verticalCenter: parent.verticalCenter
				spacing: 4

				Connection {
					glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off")
					label: "Wi-Fi"
					detail: !Connectivity.wifiAvailable ? "Not available" : !Connectivity.wifi ? "Off" : Connectivity.network || "Not connected"
					on: Connectivity.wifi
					available: Connectivity.wifiAvailable
					page: "wifi"
					onToggled: Connectivity.toggleWifi()
				}

				Connection {
					glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off")
					label: "Bluetooth"
					detail: !Connectivity.bluetoothAvailable ? "Not available" : !Connectivity.bluetooth ? "Off" : Connectivity.device || "On"
					on: Connectivity.bluetooth
					available: Connectivity.bluetoothAvailable
					page: "bluetooth"
					onToggled: Connectivity.toggleBluetooth()
				}

				Connection {
					glyph: Connectivity.airplane ? Icons.g("plane") : Icons.g("plane-off")
					label: "Airplane mode"
					detail: Connectivity.airplane ? "Wi-Fi and Bluetooth off" : "Off"
					on: Connectivity.airplane
					available: Connectivity.wifiAvailable || Connectivity.bluetoothAvailable
					onToggled: Connectivity.toggleAirplane()
				}
			}
		}

		Column {
			spacing: 10

			RoundTile {
				width: root.half
				height: 58
				glyph: Notifications.dnd ? Icons.g("bell-off") : Icons.g("bell")
				label: "Do Not Disturb"
				detail: Notifications.dnd ? "On" : "Off"
				on: Notifications.dnd
				onClicked: Notifications.dnd = !Notifications.dnd
			}

			RoundTile {
				width: root.half
				height: 58
				glyph: Icons.g("video")
				label: "Screen recording"
				detail: Recorder.recording ? "Recording" : "Off"
				on: Recorder.recording
				onClicked: Recorder.toggle()
			}
		}
	}

	Row {
		spacing: 10

		RoundTile {
			width: root.quarter
			wide: false
			glyph: Icons.g("moon")
			label: "Night light"
			on: NightLight.active
			available: NightLight.available
			onClicked: NightLight.toggle()
		}

		RoundTile {
			width: root.quarter
			wide: false
			glyph: Icons.g("coffee")
			label: "Awake"
			on: Idle.awake
			onClicked: Idle.awake = !Idle.awake
		}

		RoundTile {
			width: root.quarter
			wide: false
			glyph: Audio.micMuted ? Icons.g("microphone-off") : Icons.g("microphone")
			label: "Microphone"
			on: !Audio.micMuted
			onClicked: Audio.toggleMic()
		}

		RoundTile {
			width: root.quarter
			wide: false
			glyph: Icons.g("sun-moon")
			label: "Dark mode"
			on: Theme.palette.mode !== "light"
			onClicked: Quickshell.execDetached(["theme", "mode", "toggle"])
		}
	}

	// a card with a title row (and something at its right), then its content
	component Card: Rectangle {
		default property alias content: inner.data
		property string heading

		width: root.width
		height: inner.implicitHeight + 24
		radius: Theme.radiusCard + 4
		color: Qt.alpha(Theme.surface, 0.62)

		Column {
			id: inner

			x: 12
			y: 12
			width: parent.width - 24
			spacing: 4
		}
	}

	// the levels in one card, each icon saying what it is: the display, then the sound out and in, each
	// with its device to pick
	Card {
		LevelBar {
			visible: Brightness.available
			width: parent.width
			glyph: Icons.g("sun")
			value: Brightness.value
			onMoved: value => Brightness.set(value)
		}

		LevelBar {
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

		LevelBar {
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
	}

	// TLP's profile holds until the next plug or unplug resets it to balanced or the power saver; the
	// highlight slides to the one chosen
	Rectangle {
		id: profiles

		readonly property var choices: [
			{ name: "power-saver", label: "Quiet", glyph: "leaf" },
			{ name: "balanced", label: "Balanced", glyph: "scale" },
			{ name: "performance", label: "Performance", glyph: "flame" }
		]
		readonly property int chosen: Math.max(0, choices.findIndex(c => c.name === Power.profile))
		readonly property real cell: (width - 6) / 3

		visible: Power.available
		width: root.width
		height: 38
		radius: Theme.radiusCard
		color: Qt.alpha(Theme.fg, 0.07)

		Rectangle {
			x: 3 + profiles.chosen * profiles.cell
			y: 3
			width: profiles.cell
			height: parent.height - 6
			radius: Theme.radiusCard - 3
			color: Theme.bg

			Behavior on x {
				NumberAnimation {
					duration: Theme.normal
					easing.type: Theme.curve
				}
			}
		}

		Row {
			x: 3
			y: 3

			Repeater {
				model: profiles.choices

				delegate: Item {
					id: choice

					required property var modelData
					required property int index
					readonly property bool on: profiles.chosen === index

					width: profiles.cell
					height: profiles.height - 6

					Row {
						anchors.centerIn: parent
						spacing: 6

						Glyph {
							anchors.verticalCenter: parent.verticalCenter
							glyph: Icons.g(choice.modelData.glyph)
							color: choice.on ? Theme.fg : Theme.fgMuted
							font.pixelSize: 14
						}

						UiText {
							anchors.verticalCenter: parent.verticalCenter
							text: choice.modelData.label
							color: choice.on ? Theme.fg : Theme.fgMuted
							font.pixelSize: Theme.textCaption
							font.weight: Font.Medium
						}
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Power.setProfile(choice.modelData.name)
					}
				}
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
			height: 26
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

	// only while something plays (an empty card was just a big blank)
	MediaCard {
		visible: Media.players.length > 0
		width: parent.width
	}

	// the date, and the battery: how full, and how long it lasts or takes to fill
	Item {
		width: root.width
		height: 24

		UiText {
			anchors.left: parent.left
			anchors.leftMargin: 4
			anchors.verticalCenter: parent.verticalCenter
			text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
			color: Theme.fgMuted
			font.pixelSize: Theme.textCaption
		}

		Row {
			readonly property real remaining: Battery.charging ? Battery.device?.timeToFull ?? 0 : Battery.device?.timeToEmpty ?? 0
			readonly property bool low: !Battery.charging && Battery.percent <= Battery.threshold

			visible: Battery.present
			anchors.right: parent.right
			anchors.rightMargin: 4
			anchors.verticalCenter: parent.verticalCenter
			spacing: 6

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g(Battery.charging ? "battery-charging" : "battery-2")
				color: parent.low ? Theme.error : Battery.charging ? Theme.success : Theme.fgMuted
				font.pixelSize: 15
			}

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				text: Math.round(Battery.percent) + "%" + (Battery.device?.state === UPowerDeviceState.FullyCharged ? " · full" : parent.remaining > 60 ? " · " + root.duration(parent.remaining) + (Battery.charging ? " to full" : " left") : Battery.charging ? " · charging" : "")
				color: parent.low ? Theme.error : Theme.fgMuted
				font.pixelSize: Theme.textCaption
				font.features: ({ tnum: 1 })
			}
		}
	}
}
