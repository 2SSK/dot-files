pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import qs
import qs.services
import qs.widgets

// Wi-Fi: networks by signal (in bars; a lock on secured ones), the connected one first. A click connects, asking for a password when
// NetworkManager has none for it; failures show under the network.
Column {
	id: root

	readonly property string title: "Wi-Fi"
	readonly property var actions: [
		{ glyph: Icons.g("refresh"), on: scanning, act: () => rescan(), show: Connectivity.wifi },
		{ glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off"), on: Connectivity.wifi, act: () => Connectivity.toggleWifi() }
	]
	property bool scanning: false // a refresh asked for, lit for a few seconds while NetworkManager scans
	readonly property var devices: Array.from(Networking.devices.values).filter(d => d.type === DeviceType.Wifi)
	readonly property var networks: devices.reduce((all, d) => all.concat(Array.from(d.networks.values)), []).filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
	property var asking: null
	property var failed: null // the network whose last try failed, and why: { network, reason }

	function scan(on: bool): void {
		devices.forEach(d => d.scannerEnabled = on);
	}

	// nmcli's rescan is allowed for the logged-in user; restarting the scanner makes the list pick it up
	function rescan(): void {
		scanning = true;
		scanLit.restart();
		Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
		scan(false);
		scan(true);
	}

	spacing: 8

	// scan while open, also on a card that appears or Wi-Fi turned on after it opened
	onDevicesChanged: scan(Connectivity.wifi)
	Component.onCompleted: scan(Connectivity.wifi)
	Component.onDestruction: scan(false)

	Timer {
		id: scanLit

		interval: 4000
		onTriggered: root.scanning = false
	}

	Connections {
		target: Connectivity

		function onWifiChanged(): void {
			root.scan(Connectivity.wifi);
		}
	}

	UiText {
		visible: !Connectivity.wifiAvailable || !Connectivity.wifi
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		text: Connectivity.wifiBlocked ? "Wi-Fi is blocked (the airplane-mode key, or rfkill)." : !Connectivity.wifiAvailable ? "No Wi-Fi here (it needs NetworkManager and a Wi-Fi card)." : "Wi-Fi is off."
		wrapMode: Text.Wrap
		color: Theme.fgMuted
	}

	Repeater {
		// a ScriptModel keeps each row as signal strengths reorder them; a plain array would rebuild them all,
		// wiping a password being typed
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
				// the signal in bars
				glyph: Icons.g(["wifi-0", "wifi-1", "wifi-2", "wifi"][Math.min(3, Math.floor(entry.modelData.signalStrength * 4))])
				label: entry.modelData.name
				detail: entry.modelData.connected ? "Connected" : entry.modelData.stateChanging ? "Connecting…" : entry.modelData.known ? "Saved" : entry.open ? "Open" : entry.personal ? "Secured" : "Enterprise: use nmtui"
				active: entry.modelData.connected
				onClicked: {
					if (entry.modelData.connected || entry.modelData.stateChanging)
						return;
					if (entry.asking) {
						root.asking = null;
						return;
					}
					root.failed = null;
					root.asking = null;
					entry.modelData.connect(); // asks for a password only if this fails for want of one
				}

				Glyph {
					visible: !entry.open
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g("lock")
					color: Theme.fgMuted
					font.pixelSize: 14
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

			UiText {
				visible: entry.failure !== ""
				leftPadding: 16
				text: entry.failure
				color: Theme.error
				font.pixelSize: Theme.textLabel
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
