import QtQuick
import qs
import qs.services
import qs.widgets

// System monitor: CPU, memory and temperature with their last two minutes, then disk, uptime,
// load, and last the GPU and the network.
Column {
	id: root

	readonly property string title: "System monitor"
	readonly property var actions: []

	// while this page is open the NVIDIA card may be asked about (Stats.detail)
	Component.onCompleted: Stats.detail++
	Component.onDestruction: Stats.detail--

	function speed(bytes: real): string {
		return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB/s" : bytes >= 1024 ? Math.round(bytes / 1024) + " KB/s" : Math.round(bytes) + " B/s";
	}

	function uptime(seconds: real): string {
		const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60);
		return d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` : `${m}m`;
	}

	spacing: 12

	Repeater {
		model: [
			{ glyph: Icons.g("gauge"), label: "CPU", value: Math.round(Stats.cpu * 100) + "%", history: Stats.cpuHistory, max: 1, show: true },
			{ glyph: Icons.g("cpu"), label: "Memory", value: `${Stats.memUsed.toFixed(1)} / ${Stats.memTotal.toFixed(1)} GiB`, history: Stats.memHistory, max: 1, show: true },
			{ glyph: Icons.g("flame"), label: "Temperature", value: Math.round(Stats.temp) + " °C", history: Stats.tempHistory, max: 100, show: Stats.temp >= 0 }
		]

		delegate: Rectangle {
			id: card

			required property var modelData

			visible: modelData.show
			width: parent.width
			height: 104
			radius: 14
			color: Qt.alpha(Theme.surface, 0.8)
			clip: true

			Graph {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: 56
				values: card.modelData.history
				max: card.modelData.max
			}

			Row {
				x: 16
				y: 14
				spacing: 10

				Glyph {
					glyph: card.modelData.glyph
					font.pixelSize: 18
					color: Theme.primary
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: card.modelData.label
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 13
					font.weight: Font.Medium
				}
			}

			Label {
				anchors.right: parent.right
				anchors.rightMargin: 16
				y: 14
				text: card.modelData.value
				font.pixelSize: 15
			}
		}
	}

	Row {
		width: parent.width
		spacing: 12

		Repeater {
			model: [
				{ label: "Disk", value: `${Stats.diskUsed.toFixed(0)} / ${Stats.diskTotal.toFixed(0)} GiB`, ratio: Stats.diskTotal > 0 ? Stats.diskUsed / Stats.diskTotal : 0 },
				{ label: "Up", value: root.uptime(Stats.uptime) },
				{ label: "Load", value: Stats.load }
			]

			delegate: Rectangle {
				id: tile

				required property var modelData

				width: (parent.width - 24) / 3
				height: 76
				radius: 14
				color: Qt.alpha(Theme.surface, 0.8)

				Column {
					x: 14
					anchors.verticalCenter: parent.verticalCenter
					width: parent.width - 28
					spacing: 6

					Text {
						text: tile.modelData.label
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.pixelSize: 12
					}

					Label {
						width: parent.width
						horizontalAlignment: Text.AlignLeft
						elide: Text.ElideRight
						text: tile.modelData.value
						font.pixelSize: 14
					}

					Rectangle {
						visible: tile.modelData.ratio !== undefined
						width: parent.width
						height: 4
						radius: 2
						color: Qt.alpha(Theme.overlay, 0.9)

						Rectangle {
							width: parent.width * (tile.modelData.ratio ?? 0)
							height: parent.height
							radius: 2
							color: Theme.primary
						}
					}
				}
			}
		}
	}

	// the GPU and the network, side by side, each with its last two minutes
	Row {
		width: parent.width
		spacing: 12

		Repeater {
			model: [
				{ glyph: Icons.g("device-desktop"), label: "GPU", value: Stats.gpuName ? `${Stats.gpuName}  ${Math.round(Stats.gpu * 100)}%` : "None found", detail: (Stats.gpuName === "Intel" ? `${Math.round(Stats.gpuFreq)} MHz` : "") + (Stats.dgpuStatus ? `${Stats.gpuName === "Intel" ? "  ·  " : ""}NVIDIA ${Stats.dgpuAwake ? (Stats.dgpu || "awake") : "asleep"}` : ""), history: Stats.gpuHistory, second: [], max: 1 },
				{ glyph: Icons.g("wifi"), label: "Network", value: "↓ " + root.speed(Stats.netDown), detail: "↑ " + root.speed(Stats.netUp), history: Stats.netDownHistory, second: Stats.netUpHistory, max: Math.max(65536, ...Stats.netDownHistory, ...Stats.netUpHistory) }
			]

			delegate: Rectangle {
				id: half

				required property var modelData

				width: (parent.width - 12) / 2
				height: 118
				radius: 14
				color: Qt.alpha(Theme.surface, 0.8)
				clip: true

				Graph {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					height: 48
					values: half.modelData.history
					max: half.modelData.max
				}

				Graph {
					visible: half.modelData.second.length > 0
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					height: 48
					values: half.modelData.second
					max: half.modelData.max
					tint: Theme.secondary
				}

				Row {
					x: 16
					y: 14
					spacing: 10

					Glyph {
						glyph: half.modelData.glyph
						font.pixelSize: 18
						color: Theme.primary
					}

					Text {
						anchors.verticalCenter: parent.verticalCenter
						text: half.modelData.label
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: Font.Medium
					}
				}

				Label {
					anchors.right: parent.right
					anchors.rightMargin: 16
					y: 14
					text: half.modelData.value
					font.pixelSize: 14
				}

				Text {
					anchors.right: parent.right
					anchors.rightMargin: 16
					y: 40
					text: half.modelData.detail
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
				}
			}
		}
	}
}
