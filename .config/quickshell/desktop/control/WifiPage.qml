pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking
import qs
import qs.services
import qs.widgets

// Wi-Fi: networks by signal (the connected one first). A click on a saved or open network connects;
// a new secured one asks for its password. Scans while the page is open.
Column {
	id: root

	readonly property string title: "Wi-Fi"
	readonly property var actions: [{ glyph: Connectivity.wifi ? "\u{F05A9}" : "\u{F05AA}", on: Connectivity.wifi, act: () => Connectivity.toggleWifi() }]
	readonly property var devices: Array.from(Networking.devices.values).filter(d => d.type === DeviceType.Wifi)
	readonly property var networks: devices.reduce((all, d) => all.concat(Array.from(d.networks.values)), []).filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
	property var asking: null // the network waiting for a password

	spacing: 8

	// scan while open
	Component.onCompleted: devices.forEach(d => d.scannerEnabled = true)
	Component.onDestruction: devices.forEach(d => d.scannerEnabled = false)

	Text {
		visible: !Connectivity.wifiAvailable || !Connectivity.wifi
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		text: !Connectivity.wifiAvailable ? "No Wi-Fi here (it needs NetworkManager and a Wi-Fi card)." : "Wi-Fi is off."
		wrapMode: Text.Wrap
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	Repeater {
		model: Connectivity.wifi ? root.networks : []

		delegate: Column {
			id: entry

			required property WifiNetwork modelData
			readonly property bool secured: modelData.security !== WifiSecurityType.Open

			width: root.width
			spacing: 6

			ListRow {
				glyph: "\u{F05A9}"
				label: entry.modelData.name
				detail: entry.modelData.connected ? "Connected" : entry.modelData.stateChanging ? "Connecting…" : entry.modelData.known ? "Saved" : entry.secured ? "Secured" : "Open"
				active: entry.modelData.connected
				opacity: 0.45 + 0.55 * entry.modelData.signalStrength
				onClicked: {
					if (entry.modelData.connected)
						return;
					if (entry.modelData.known || !entry.secured)
						entry.modelData.connect();
					else
						root.asking = entry.modelData;
				}

				SmallButton {
					visible: entry.modelData.connected
					text: "Disconnect"
					onClicked: entry.modelData.disconnect()
				}

				SmallButton {
					visible: entry.modelData.known && !entry.modelData.connected
					text: "Forget"
					onClicked: entry.modelData.forget()
				}
			}

			Row {
				visible: root.asking === entry.modelData
				width: parent.width
				spacing: 8

				TextField {
					id: password

					width: parent.width - join.width - 8
					placeholder: "Password for " + entry.modelData.name
					password: true
					onVisibleChanged: if (visible) focusField()
					onAccepted: text => {
						entry.modelData.connectWithPsk(text);
						root.asking = null;
					}
				}

				SmallButton {
					id: join

					anchors.verticalCenter: parent.verticalCenter
					accent: true
					text: "Join"
					onClicked: {
						entry.modelData.connectWithPsk(password.text);
						root.asking = null;
					}
				}
			}
		}
	}
}
