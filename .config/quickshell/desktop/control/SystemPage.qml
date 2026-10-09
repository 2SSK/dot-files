import QtQuick
import qs
import qs.services
import qs.widgets

// System monitor: CPU, memory and temperature with their last two minutes, then disk, uptime, load.
Column {
	readonly property string title: "System monitor"
	readonly property var actions: []

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
				{ label: "Up", value: uptime(Stats.uptime) },
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
}
