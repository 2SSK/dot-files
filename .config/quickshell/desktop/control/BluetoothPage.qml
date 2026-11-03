pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.settings
import qs.widgets

// Bluetooth: this laptop (its name, and whether nearby devices can find it), your devices (connected
// first, each with its kind and battery), then ones nearby, looked for while this is open. Nameless
// devices (phones and beacons advertising only an address) are left out.
Column {
	id: root

	readonly property string title: "Bluetooth"
	readonly property var actions: [
		{ glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off"), on: Connectivity.bluetooth, act: () => Connectivity.toggleBluetooth() }
	]
	readonly property var named: Array.from(Bluetooth.devices.values).filter(d => d.name && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
	readonly property var mine: named.filter(d => d.paired).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
	readonly property var nearby: named.filter(d => !d.paired).sort((a, b) => a.name.localeCompare(b.name))

	// looks while it shows (the page is kept: hidden while the panel is closed or another page shows)
	readonly property bool looking: visible && Connectivity.bluetooth

	function scan(on: bool): void {
		if (Connectivity.adapter && Connectivity.adapter.discovering !== on)
			Connectivity.adapter.discovering = on;
	}

	// BlueZ's icon name for the kind of device: [glyph, what to call it]
	readonly property var kinds: [["input-keyboard", "keyboard", "Keyboard"], ["input-mouse", "mouse", "Mouse"], ["input-tablet", "mouse", "Tablet"], ["input-gaming", "device-gamepad-2", "Controller"],
		["audio-head", "headphones", "Headphones"], ["audio", "device-speaker", "Speaker"], ["phone", "device-mobile", "Phone"], ["computer", "device-laptop", "Computer"], ["watch", "device-watch", "Watch"]]

	function kindOf(icon: string): var {
		return kinds.find(([prefix]) => icon.startsWith(prefix)) ?? ["", "bluetooth", ""];
	}

	spacing: 8

	onLookingChanged: scan(looking)
	Component.onCompleted: scan(looking)
	Component.onDestruction: scan(false)

	UiText {
		visible: !Connectivity.bluetoothAvailable || !Connectivity.bluetooth
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: !Connectivity.bluetoothAvailable ? "No Bluetooth here (it needs BlueZ and an adapter)." : "Bluetooth is off."
		color: Theme.fgMuted
	}

	// this laptop: what others see it as, and whether they can find it
	Rectangle {
		visible: Connectivity.bluetooth
		width: parent.width
		height: 64
		radius: Theme.radiusCard
		color: Qt.alpha(Theme.primary, 0.13)
		border.width: 1
		border.color: Qt.alpha(Theme.primary, 0.35)

		Rectangle {
			id: laptopIcon

			x: 14
			anchors.verticalCenter: parent.verticalCenter
			width: 38
			height: 38
			radius: Theme.radiusCard
			color: Qt.alpha(Theme.primary, 0.2)

			Glyph {
				anchors.centerIn: parent
				glyph: Icons.g("device-laptop")
				color: Theme.primary
				font.pixelSize: 18
			}
		}

		Column {
			anchors.left: laptopIcon.right
			anchors.leftMargin: 14
			anchors.right: visible_.left
			anchors.rightMargin: 12
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2

			UiText {
				width: parent.width
				text: Connectivity.adapter?.name ?? "This laptop"
				elide: Text.ElideRight
				font.weight: Font.DemiBold
			}

			UiText {
				width: parent.width
				text: Connectivity.adapter?.discoverable ? "Visible to nearby devices" : "Hidden: only your devices see it"
				elide: Text.ElideRight
				color: Connectivity.adapter?.discoverable ? Theme.primary : Theme.fgMuted
				font.pixelSize: Theme.textLabel
			}
		}

		Toggle {
			id: visible_

			anchors.right: parent.right
			anchors.rightMargin: 16
			anchors.verticalCenter: parent.verticalCenter
			checked: Connectivity.adapter?.discoverable ?? false
			onToggled: on => {
				if (Connectivity.adapter)
					Connectivity.adapter.discoverable = on;
			}
		}
	}

	component Heading: Row {
		property alias text: label.text
		property bool busy

		topPadding: 6
		leftPadding: 4
		spacing: 8

		UiText {
			id: label

			color: Theme.fgMuted
			font.pixelSize: Theme.textLabel
			font.weight: Font.DemiBold
		}

		// looking for devices: a turning spinner
		Glyph {
			visible: parent.busy
			anchors.verticalCenter: label.verticalCenter
			glyph: Icons.g("loader-2")
			color: Theme.fgMuted
			font.pixelSize: 13

			RotationAnimation on rotation {
				running: parent.visible
				from: 0
				to: 360
				duration: 900
				loops: Animation.Infinite
			}
		}
	}

	component Device: ListRow {
		id: row

		required property BluetoothDevice modelData
		readonly property string trouble: Connectivity.trouble[modelData?.address ?? ""] ?? ""
		readonly property bool repairing: Connectivity.repairing !== "" && Connectivity.repairing === modelData?.address
		readonly property var kind: root.kindOf(modelData?.icon ?? "")
		readonly property int battery: modelData?.batteryAvailable ? Math.round(modelData.battery * 100) : -1

		width: root.width
		glyph: Icons.g(kind[1])
		label: modelData?.name ?? ""
		detail: [repairing ? "Pairing again…" : trouble ? trouble : modelData?.connected ? "Connected" : modelData?.pairing ? "Pairing…" : modelData?.state === BluetoothDeviceState.Connecting ? "Connecting…" : modelData?.paired ? "Not connected" : "Nearby", kind[2]].filter(p => p).join(" · ")
		active: modelData?.connected ?? false
		onClicked: modelData?.connected ? modelData?.disconnect() : modelData?.paired ? Connectivity.connectTo(modelData) : Connectivity.pairWith(modelData)

		// the battery, as a gauge and a number; red when low
		Row {
			visible: row.battery >= 0
			anchors.verticalCenter: parent.verticalCenter
			rightPadding: 4
			spacing: 4

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g(["battery-1", "battery-2", "battery-3", "battery-4"][Math.min(3, Math.floor(row.battery / 25))])
				color: row.battery <= 20 ? Theme.error : Theme.fgMuted
				font.pixelSize: 16
			}

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				text: row.battery + "%"
				color: row.battery <= 20 ? Theme.error : Theme.fgMuted
				font.pixelSize: Theme.textLabel
				font.family: Theme.fontMono
			}
		}

		// a device in trouble: forgotten and paired again (and connected), the fix for a stale bond
		SmallButton {
			visible: row.trouble !== "" && !row.repairing
			text: "Re-pair"
			accent: true
			onClicked: Connectivity.repair(row.modelData)
		}

		SmallButton {
			visible: !row.trouble && !row.repairing
			text: row.modelData?.connected ? "Disconnect" : row.modelData?.paired ? "Connect" : "Pair"
			accent: !row.modelData?.connected
			onClicked: row.clicked()
		}

		SmallButton {
			visible: (row.modelData?.paired ?? false) && !row.modelData?.connected && !row.repairing
			text: "Forget"
			onClicked: row.modelData?.forget()
		}
	}

	Heading {
		visible: Connectivity.bluetooth && root.mine.length > 0
		text: "My devices"
	}

	// a ScriptModel keeps each row as a scan reorders them
	Repeater {
		model: ScriptModel {
			values: Connectivity.bluetooth ? root.mine : []
		}

		delegate: Device {}
	}

	Heading {
		visible: Connectivity.bluetooth
		text: "Nearby"
		busy: Connectivity.adapter?.discovering ?? false
	}

	Repeater {
		model: ScriptModel {
			values: Connectivity.bluetooth ? root.nearby : []
		}

		delegate: Device {}
	}

	UiText {
		visible: Connectivity.bluetooth && root.nearby.length === 0
		leftPadding: 4
		text: Connectivity.adapter?.discovering ? "Looking for devices… Put the one you want in pairing mode." : "No devices nearby."
		color: Theme.fgMuted
		font.pixelSize: Theme.textLabel
	}
}
