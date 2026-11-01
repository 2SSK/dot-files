pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.widgets

// Settings → Sound: where sound goes and comes from (PipeWire's devices, by their short names), each
// side's volume, and every app playing now with a volume of its own.
Column {
	id: page

	spacing: 22

	readonly property var nodes: Array.from(Pipewire.nodes.values)
	readonly property var outputs: nodes.filter(n => n.audio && !n.isStream && n.isSink)
	readonly property var inputs: nodes.filter(n => n.audio && !n.isStream && !n.isSink)
	// apps playing: playback streams (a recording app's capture stream isn't a volume you'd set here)
	readonly property var apps: nodes.filter(n => n.audio && n.isStream && n.properties["media.class"] === "Stream/Output/Audio")

	function nameOf(node: PwNode): string {
		return node?.nickname || node?.description || node?.name || "";
	}

	// the volumes of the apps (and the devices) are only known while something tracks them
	PwObjectTracker {
		objects: page.apps.concat(page.outputs, page.inputs)
	}

	component Device: SettingRow {
		id: row

		required property PwNode modelData
		required property bool output
		readonly property bool chosen: modelData === (output ? Audio.sink : Audio.source)

		label: page.nameOf(modelData)
		hint: chosen ? (output ? "Sound plays here" : "Listening here") : ""

		Rectangle {
			width: 22
			height: 22
			radius: 11
			color: "transparent"
			border.width: 2
			border.color: row.chosen ? Theme.primary : Qt.alpha(Theme.fg, 0.35)

			Rectangle {
				visible: row.chosen
				anchors.centerIn: parent
				width: 10
				height: 10
				radius: 5
				color: Theme.primary
			}
		}

		MouseArea {
			parent: row
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				if (row.output)
					Pipewire.preferredDefaultAudioSink = row.modelData;
				else
					Pipewire.preferredDefaultAudioSource = row.modelData;
			}
		}
	}

	Section {
		title: "Output"

		SettingRow {
			label: "Volume"
			hint: Audio.muted ? "Muted: the speaker icon in the control center unmutes" : ""
			Range {
				from: 0
				to: 1
				step: 0.01
				value: Audio.volume
				format: v => Math.round(v * 100) + " %"
				onMoved: value => Audio.setVolume(value)
			}
		}

		Repeater {
			model: page.outputs

			delegate: Device {
				output: true
			}
		}
	}

	Section {
		title: "Input"

		SettingRow {
			label: "Volume"
			hint: Audio.micMuted ? "Muted" : ""
			Range {
				from: 0
				to: 1
				step: 0.01
				value: Audio.micVolume
				format: v => Math.round(v * 100) + " %"
				onMoved: value => Audio.setMic(value)
			}
		}

		Repeater {
			model: page.inputs

			delegate: Device {
				output: false
			}
		}
	}

	Section {
		title: "Apps"

		SettingRow {
			visible: page.apps.length === 0
			label: "Nothing is playing"
			hint: "Apps show here while they play, each with a volume of its own."
		}

		Repeater {
			model: page.apps

			delegate: SettingRow {
				id: app

				required property PwNode modelData
				readonly property var props: modelData?.properties ?? {}

				label: props["application.name"] || page.nameOf(modelData)
				hint: props["media.name"] ?? ""

				Row {
					spacing: 12

					IconButton {
						anchors.verticalCenter: parent.verticalCenter
						glyph: app.modelData?.audio?.muted ? Icons.g("volume-off") : Icons.g("volume")
						onClicked: if (app.modelData?.audio) app.modelData.audio.muted = !app.modelData.audio.muted
					}

					Range {
						anchors.verticalCenter: parent.verticalCenter
						from: 0
						to: 1
						step: 0.01
						value: app.modelData?.audio?.volume ?? 0
						format: v => Math.round(v * 100) + " %"
						onMoved: value => {
							if (app.modelData?.audio)
								app.modelData.audio.volume = value;
						}
					}
				}
			}
		}
	}
}
