pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs
import qs.services
import qs.widgets

// Wi-Fi: the network you're on as a card of its own (band, security, speed, addresses), then the
// saved networks in range and the others, by signal. A click joins, asking for a password when
// NetworkManager has none for it; failures show under the network. Joining a hidden network is at the
// end. Band, speed and security names come from nmcli (Quickshell has only the signal and the kind).
Column {
	id: root

	readonly property string title: "Wi-Fi"
	readonly property var actions: [
		{ glyph: Icons.g("refresh"), on: scanning, act: () => rescan(), show: Connectivity.wifi },
		{ glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off"), on: Connectivity.wifi, act: () => Connectivity.toggleWifi() }
	]
	property bool scanning: false // a refresh asked for, lit for a few seconds while NetworkManager scans
	readonly property var devices: Array.from(Networking.devices.values).filter(d => d.type === DeviceType.Wifi)
	readonly property var networks: devices.reduce((all, d) => all.concat(Array.from(d.networks.values)), []).filter(n => n.name).sort((a, b) => b.signalStrength - a.signalStrength)
	readonly property var current: networks.find(n => n.connected) ?? null
	readonly property var saved: networks.filter(n => n.known && !n.connected)
	readonly property var others: networks.filter(n => !n.known && !n.connected)
	property var asking: null
	property var failed: null // the network whose last try failed, and why: { network, reason }
	// nmcli's view: per name, the strongest access point's { band, rate, security }; and the connected
	// device's addresses
	property var details: ({})
	property var addresses: ({})

	// scans while it shows (the page is kept: hidden while the panel is closed or another page shows),
	// also on a card that appears
	readonly property bool looking: visible && Connectivity.wifi

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

	// "WPA1 WPA2" → "WPA2", "WPA2 WPA3" → "WPA3", "" → "Open"
	function securityName(raw: string): string {
		const kinds = raw.split(" ").filter(k => /^(WPA|WEP|OWE|802)/.test(k));
		return kinds.length ? kinds.sort().slice(-1)[0].replace("802.1X", "Enterprise") : "Open";
	}

	function band(mhz: int): string {
		return mhz >= 5925 ? "6 GHz" : mhz >= 4900 ? "5 GHz" : "2.4 GHz";
	}

	// nmcli -t escapes the separator inside fields as \:
	function fields(line: string): var {
		return line.replace(/\\:/g, "\u0001").split(":").map(f => f.replace(/\u0001/g, ":"));
	}

	function info(network: var): var {
		return details[network?.name ?? ""] ?? null;
	}

	function summary(network: var): string {
		const i = info(network);
		const pct = `${Math.round((network?.signalStrength ?? 0) * 100)}%`;
		return [i?.security ?? "", i?.band ?? "", pct].filter(p => p).join(" · ");
	}

	function copy(text: string): void {
		Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | desktop clipboard copy text', "sh", text]);
	}

	spacing: 8

	onLookingChanged: {
		scan(looking);
		if (looking)
			refresh.restart();
	}
	onDevicesChanged: scan(looking)
	onCurrentChanged: if (looking) refresh.restart()
	Component.onCompleted: scan(looking)
	Component.onDestruction: scan(false)

	Timer {
		id: scanLit

		interval: 4000
		onTriggered: root.scanning = false
	}

	// nmcli again every few seconds while the page shows (it reads NetworkManager's last scan; no rescan)
	Timer {
		id: refresh

		interval: 50
		repeat: false
		onTriggered: {
			list.running = true;
			if (root.current)
				show.running = true;
			else
				root.addresses = {};
			interval = 6000;
			if (root.looking)
				restart();
		}
	}

	Process {
		id: list

		command: ["nmcli", "-t", "-f", "SSID,FREQ,RATE,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
		stdout: StdioCollector {
			onStreamFinished: {
				const best = {};
				for (const line of text.split("\n").filter(l => l)) {
					const [ssid, freq, rate, signal, security] = root.fields(line);
					if (!ssid || (best[ssid] && best[ssid].signal >= +signal))
						continue;
					best[ssid] = { signal: +signal, band: freq ? root.band(parseInt(freq)) : "", rate: (rate ?? "").replace("Mbit/s", "Mb/s"), security: root.securityName(security ?? "") };
				}
				root.details = best;
			}
		}
	}

	Process {
		id: show

		command: ["sh", "-c", 'nmcli -t -f GENERAL.DEVICE,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show "$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: \'$2 == "wifi" && $3 == "connected" { print $1; exit }\')"']
		stdout: StdioCollector {
			onStreamFinished: {
				const got = { dns: [] };
				for (const line of text.split("\n")) {
					const at = line.indexOf(":");
					const key = line.slice(0, at), value = line.slice(at + 1);
					if (key === "GENERAL.DEVICE")
						got.device = value;
					else if (key.startsWith("IP4.ADDRESS") && !got.ip)
						got.ip = value.split("/")[0];
					else if (key === "IP4.GATEWAY")
						got.gateway = value;
					else if (key.startsWith("IP4.DNS"))
						got.dns.push(value);
				}
				root.addresses = got;
			}
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

	// the network you're on
	Rectangle {
		id: card

		readonly property var info: root.info(root.current)

		visible: Connectivity.wifi && root.current !== null
		width: parent.width
		height: cardColumn.implicitHeight + 28
		radius: 14
		color: Qt.alpha(Theme.primary, 0.13)
		border.width: 1
		border.color: Qt.alpha(Theme.primary, 0.35)

		Column {
			id: cardColumn

			x: 16
			y: 14
			width: parent.width - 32
			spacing: 12

			Row {
				width: parent.width
				spacing: 14

				Rectangle {
					width: 40
					height: 40
					radius: 12
					color: Qt.alpha(Theme.primary, 0.2)

					SignalBars {
						anchors.centerIn: parent
						strength: root.current?.signalStrength ?? 0
						color: Theme.primary
						size: 18
					}
				}

				Column {
					width: parent.width - 54 - cardButtons.width - 14
					anchors.verticalCenter: parent.verticalCenter
					spacing: 2

					UiText {
						width: parent.width
						text: root.current?.name ?? ""
						elide: Text.ElideRight
						font.weight: Font.DemiBold
						font.pixelSize: Theme.textBody + 1
					}

					UiText {
						width: parent.width
						text: ["Connected", root.summary(root.current)].filter(p => p).join(" · ")
						elide: Text.ElideRight
						color: Theme.primary
						font.pixelSize: Theme.textLabel
					}
				}

				Row {
					id: cardButtons

					anchors.verticalCenter: parent.verticalCenter
					spacing: 6

					SmallButton {
						text: "Disconnect"
						onClicked: root.current?.disconnect()
					}

					SmallButton {
						text: "Forget"
						onClicked: root.current?.forget()
					}
				}
			}

			// the addresses, two to a line; a click copies one
			Grid {
				width: parent.width
				columns: 2
				columnSpacing: 10
				rowSpacing: 8

				Repeater {
					model: [
						{ label: "IP address", value: root.addresses.ip ?? "" },
						{ label: "Gateway", value: root.addresses.gateway ?? "" },
						{ label: "DNS", value: (root.addresses.dns ?? []).join(", ") },
						{ label: "Link speed", value: card.info?.rate ?? "" }
					]

					delegate: Rectangle {
						id: fact

						required property var modelData

						width: (cardColumn.width - 10) / 2
						height: 46
						radius: 10
						color: factHover.hovered && fact.modelData.value ? Qt.alpha(Theme.bg, 0.55) : Qt.alpha(Theme.bg, 0.35)

						HoverHandler {
							id: factHover
						}

						MouseArea {
							anchors.fill: parent
							enabled: fact.modelData.value !== ""
							cursorShape: Qt.PointingHandCursor
							onClicked: root.copy(fact.modelData.value)
						}

						Column {
							x: 12
							anchors.verticalCenter: parent.verticalCenter
							width: parent.width - 36
							spacing: 1

							UiText {
								text: fact.modelData.label
								color: Theme.fgMuted
								font.pixelSize: Theme.textCaption
							}

							UiText {
								width: parent.width
								text: fact.modelData.value || "—"
								elide: Text.ElideRight
								font.family: Theme.fontMono
								font.pixelSize: Theme.textLabel
							}
						}

						Glyph {
							visible: factHover.hovered && fact.modelData.value !== ""
							anchors.right: parent.right
							anchors.rightMargin: 10
							anchors.verticalCenter: parent.verticalCenter
							glyph: Icons.g("copy")
							color: Theme.fgMuted
							font.pixelSize: 13
						}
					}
				}
			}
		}
	}

	component Heading: UiText {
		topPadding: 6
		leftPadding: 4
		color: Theme.fgMuted
		font.pixelSize: Theme.textLabel
		font.weight: Font.DemiBold
	}

	component Network: Column {
		id: entry

		required property WifiNetwork modelData
		readonly property int security: modelData?.security
		readonly property bool open: security === WifiSecurityType.Open || security === WifiSecurityType.Owe
		// a password is all connectWithPsk takes: WPA/WPA2/WPA3 personal
		readonly property bool personal: [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(security)
		readonly property bool asking: root.asking === modelData
		readonly property string failure: root.failed?.network === modelData ? root.failed.reason : ""

		function join(psk: string): void {
			root.failed = null;
			root.asking = null;
			modelData?.connectWithPsk(psk);
		}

		width: root.width
		spacing: 6

		Connections {
			target: entry.modelData

			function onConnectionFailed(reason: int): void {
				if (reason === ConnectionFailReason.NoSecrets && entry.personal) {
					root.asking = entry.modelData; // no password, or a wrong one: ask
					root.failed = entry.modelData?.known ? { network: entry.modelData, reason: "The saved password didn't work." } : null;
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
			label: entry.modelData?.name ?? ""
			detail: entry.modelData?.stateChanging ? "Connecting…" : !entry.open && !entry.personal ? "Enterprise: use nmtui" : root.summary(entry.modelData)
			lead: SignalBars {
				strength: entry.modelData?.signalStrength ?? 0
			}
			onClicked: {
				if (entry.modelData?.stateChanging)
					return;
				if (entry.asking) {
					root.asking = null;
					return;
				}
				root.failed = null;
				root.asking = null;
				entry.modelData?.connect(); // asks for a password only if this fails for want of one
			}

			Glyph {
				visible: !entry.open
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g("lock")
				color: Theme.fgMuted
				font.pixelSize: 14
			}

			SmallButton {
				visible: entry.modelData?.known ?? false
				text: "Forget"
				onClicked: entry.modelData?.forget()
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
				placeholder: "Password for " + entry.modelData?.name
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

	Heading {
		visible: Connectivity.wifi && root.saved.length > 0
		text: "Saved networks"
	}

	// ScriptModels keep each row as signal strengths reorder them; a plain array would rebuild them all,
	// wiping a password being typed
	Repeater {
		model: ScriptModel {
			values: Connectivity.wifi ? root.saved : []
		}

		delegate: Network {}
	}

	Heading {
		visible: Connectivity.wifi && root.others.length > 0
		text: "Other networks"
	}

	Repeater {
		model: ScriptModel {
			values: Connectivity.wifi ? root.others : []
		}

		delegate: Network {}
	}

	// a network that doesn't announce its name: nmcli joins it, the password on its stdin (not its
	// command line, which other processes can read)
	Column {
		id: hidden

		property bool open: false
		property string error: ""

		function join(): void {
			if (!ssid.text)
				return;
			error = "";
			joiner.command = ["nmcli", "--ask", "device", "wifi", "connect", ssid.text, "hidden", "yes"];
			joiner.running = true;
		}

		visible: Connectivity.wifi
		width: parent.width
		spacing: 8
		topPadding: 4

		ListRow {
			glyph: Icons.g("plus")
			label: "Join a hidden network"
			detail: joiner.running ? "Joining…" : hidden.error
			onClicked: hidden.open = !hidden.open
		}

		Column {
			visible: hidden.open
			width: parent.width
			spacing: 8

			TextField {
				id: ssid

				width: parent.width
				placeholder: "Network name"
				onVisibleChanged: if (visible) focusField()
				onAccepted: hiddenPassword.focusField()
				onKeyPressed: event => {
					if (event.key === Qt.Key_Escape) {
						hidden.open = false;
						event.accepted = true;
					}
				}
			}

			Row {
				width: parent.width
				spacing: 8

				TextField {
					id: hiddenPassword

					width: parent.width - hiddenJoin.width - 8
					placeholder: "Password (empty for an open one)"
					password: true
					revealable: true
					onAccepted: hidden.join()
					onKeyPressed: event => {
						if (event.key === Qt.Key_Escape) {
							hidden.open = false;
							event.accepted = true;
						}
					}
				}

				SmallButton {
					id: hiddenJoin

					anchors.verticalCenter: parent.verticalCenter
					accent: true
					text: "Join"
					onClicked: hidden.join()
				}
			}
		}

		Process {
			id: joiner

			stdinEnabled: true
			onStarted: write(hiddenPassword.text + "\n")
			stderr: StdioCollector {
				id: joinErrors
			}
			onExited: code => {
				if (code === 0) {
					hidden.open = false;
					ssid.text = "";
					hiddenPassword.text = "";
				} else {
					hidden.error = joinErrors.text.replace(/^Error: /, "").split("\n")[0] || "Couldn't join.";
				}
			}
		}
	}
}
