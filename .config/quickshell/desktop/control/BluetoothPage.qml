pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import qs
import qs.services
import qs.widgets

// Bluetooth: connected devices first, then paired, then ones found by a scan (the refresh button).
Column {
	id: root

	readonly property string title: "Bluetooth"
	readonly property var actions: [
		{ glyph: Icons.g("reload"), on: Connectivity.adapter?.discovering ?? false, act: () => { if (Connectivity.adapter) Connectivity.adapter.discovering = !Connectivity.adapter.discovering; }, show: Connectivity.bluetooth },
		{ glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off"), on: Connectivity.bluetooth, act: () => Connectivity.toggleBluetooth() }
	]
	readonly property var devices: Array.from(Bluetooth.devices.values).filter(d => d.name).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

	spacing: 8

	Component.onDestruction: if (Connectivity.adapter?.discovering) Connectivity.adapter.discovering = false

	Text {
		visible: !Connectivity.bluetoothAvailable || !Connectivity.bluetooth || root.devices.length === 0
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: !Connectivity.bluetoothAvailable ? "No Bluetooth here (it needs BlueZ and an adapter)." : !Connectivity.bluetooth ? "Bluetooth is off." : "No devices yet: the refresh button scans for them."
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textBody
	}

	Repeater {
		model: Connectivity.bluetooth ? root.devices : []

		delegate: ListRow {
			id: row

			required property BluetoothDevice modelData

			width: root.width
			glyph: Icons.g("bluetooth")
			label: modelData.name
			detail: (modelData.connected ? "Connected" : modelData.pairing ? "Pairing…" : modelData.paired ? "Paired" : "Found") + (modelData.batteryAvailable ? ` · ${Math.round(modelData.battery * 100)}%` : "")
			active: modelData.connected
			onClicked: modelData.connected ? modelData.disconnect() : modelData.paired ? modelData.connect() : modelData.pair()

			SmallButton {
				text: row.modelData.connected ? "Disconnect" : row.modelData.paired ? "Connect" : "Pair"
				accent: !row.modelData.connected
				onClicked: row.clicked()
			}

			SmallButton {
				visible: row.modelData.paired && !row.modelData.connected
				text: "Forget"
				onClicked: row.modelData.forget()
			}
		}
	}
}
