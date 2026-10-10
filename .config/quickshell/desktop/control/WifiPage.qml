pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import qs
import qs.services
import qs.widgets

// Wi-Fi: networks by signal (the connected one first). A click connects; when NetworkManager has no
// password for it (a new network, or a saved one whose password changed) it asks, with an eye to
// show what's typed. Failures show under the network. Scans while the page is open and Wi-Fi is on.
Column {
	id: root

	readonly property string title: "Wi-Fi"
	readonly property var actions: [{ glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off"), on: Connectivity.wifi, act: () => Connectivity.toggleWifi() }]
	readonly property var devices: Array.from(Networking.devices.values).filter(d => d.type === DeviceType.Wifi)
	readonly property var networks: devices.reduce((all, d) => all.concat(Array.from(d.networks.values)), []).filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
	property var asking: null // the network waiting for a password
	property var failed: null // the network whose last try failed, and why: { network, reason }

	function scan(on: bool): void {
		devices.forEach(d => d.scannerEnabled = on);
	}

	spacing: 8

	// scan while open, also on a card that appears or Wi-Fi turned on after it opened
	onDevicesChanged: scan(Connectivity.wifi)
	Component.onCompleted: scan(Connectivity.wifi)
	Component.onDestruction: scan(false)

	Connections {
		target: Connectivity

		function onWifiChanged(): void {
			root.scan(Connectivity.wifi);
		}
	}

	Text {
		visible: !Connectivity.wifiAvailable || !Connectivity.wifi
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		text: Connectivity.wifiBlocked ? "Wi-Fi is blocked (the airplane-mode key, or rfkill)." : !Connectivity.wifiAvailable ? "No Wi-Fi here (it needs NetworkManager and a Wi-Fi card)." : "Wi-Fi is off."
		wrapMode: Text.Wrap
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: 14
	}

	Repeater {
		// a ScriptModel keeps each row while signal strengths reorder the list: a plain array would
		// rebuild them all, wiping a password being typed
		model: ScriptModel {
			values: Connectivity.wifi ? root.networks : []
		}

		delegate: Column {
			id: entry

			required property WifiNetwork modelData
			readonly property int security: modelData.security
			readonly property bool open: security === WifiSecurityType.Open || security === WifiSecurityType.Owe
			// a password is all connectWithPsk takes: WPA/WPA2/WPA3 personal
			readonly property bool personal: [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(security)
			readonly property bool asking: root.asking === modelData
			readonly property string failure: root.failed?.network === modelData ? root.failed.reason : ""

			function join(psk: string): void {
				root.failed = null;
				root.asking = null;
				modelData.connectWithPsk(psk);
			}

			width: root.width
			spacing: 6

			Connections {
				target: entry.modelData

				function onConnectionFailed(reason: int): void {
					if (reason === ConnectionFailReason.NoSecrets && entry.personal) {
						root.asking = entry.modelData; // no password, or a wrong one: ask
						root.failed = entry.modelData.known ? { network: entry.modelData, reason: "The saved password didn't work." } : null;
					} else {
						root.failed = { network: entry.modelData, reason: ({
								[ConnectionFailReason.NoSecrets]: "It needs a login this panel can't give: use nmtui.",
								[ConnectionFailReason.WifiAuthTimeout]: "No answer: wrong password, or too far away.",
								[ConnectionFailReason.WifiNetworkLost]: "The network went out of range.",
								[ConnectionFailReason.WifiClientDisconnected]: "Disconnected while joining.",
								[ConnectionFailReason.WifiClientFailed]: "Couldn't join."
							})[reason] ?? "Couldn't join." };
					}
				}
			}

			ListRow {
				glyph: Icons.g("wifi")
				label: entry.modelData.name
				detail: (entry.modelData.connected ? "Connected" : entry.modelData.stateChanging ? "Connecting…" : entry.modelData.known ? "Saved" : entry.open ? "Open" : entry.personal ? "Secured" : "Enterprise: use nmtui") + " · " + Math.round(entry.modelData.signalStrength * 100) + "%"
				active: entry.modelData.connected
				onClicked: {
					if (entry.modelData.connected || entry.modelData.stateChanging)
						return;
					if (entry.asking) {
						root.asking = null; // a second click folds the prompt away
						return;
					}
					root.failed = null;
					root.asking = null;
					entry.modelData.connect(); // asks for a password only if this fails for want of one
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

			Text {
				visible: entry.failure !== ""
				leftPadding: 16
				text: entry.failure
				color: Theme.error
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.weight: Theme.textWeight
				font.pixelSize: 13
			}

			Row {
				visible: entry.asking
				width: parent.width
				spacing: 8

				TextField {
					id: password

					width: parent.width - join.width - 8
					placeholder: "Password for " + entry.modelData.name
					password: true
					revealable: true
					onVisibleChanged: {
						text = "";
						revealed = false;
						if (visible)
							focusField();
					}
					onAccepted: text => entry.join(text)
					// Escape folds the prompt away, not the whole control center
					onKeyPressed: event => {
						if (event.key === Qt.Key_Escape) {
							root.asking = null;
							event.accepted = true;
						}
					}
				}

				SmallButton {
					id: join

					anchors.verticalCenter: parent.verticalCenter
					accent: true
					text: "Join"
					onClicked: entry.join(password.text)
				}
			}
		}
	}
}
