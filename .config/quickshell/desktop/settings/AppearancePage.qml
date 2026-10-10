pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → Appearance: The theme (family and dark or light, through the theme command) and the night light.
Column {
	id: page

	spacing: 22

	property string family: ""
	property string mode: ""
	property var families: []

	function theme(args: var): void {
		apply.command = ["theme", ...args];
		apply.running = true;
	}

	// the themes, and which one is on (read when this page opens)
	Process {
		running: true
		command: ["theme", "list"]
		stdout: StdioCollector {
			onStreamFinished: page.families = text.split("\n").filter(line => line.trim()).map(line => line.replace("*", "").trim())
		}
	}

	Process {
		id: current

		running: true
		command: ["theme", "current"]
		stdout: StdioCollector {
			onStreamFinished: {
				const [family, mode] = text.trim().split(" ");
				page.family = family;
				page.mode = mode;
			}
		}
	}

	Process {
		id: apply

		onExited: current.running = true
	}

	Section {
		title: "Theme"

		SettingRow {
			label: "Mode"
			Choice {
				options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]
				value: page.mode
				onPicked: value => page.theme(["mode", value])
			}
		}

		Flow {
			width: parent.width
			spacing: 8
			topPadding: 6

			Repeater {
				model: page.families

				delegate: Rectangle {
					id: swatch

					required property string modelData
					readonly property bool on: page.family === modelData

					width: 150
					height: 52
					radius: 12
					color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.surface, 0.55)
					border.width: on ? 0 : 1
					border.color: Qt.alpha(Theme.border, 0.6)

					Text {
						anchors.centerIn: parent
						text: swatch.modelData
						color: swatch.on ? Theme.primaryText : Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 14
						font.weight: Font.Medium
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: page.theme(["set", swatch.modelData])
					}
				}
			}
		}
	}

	Section {
		title: "Night light"

		SettingRow {
			label: "On now"
			hint: NightLight.available ? "A warmer screen; also in the control center." : "Needs gammastep (packages/base.txt)."
			Toggle {
				checked: NightLight.active
				onToggled: NightLight.toggle()
			}
		}

		SettingRow {
			label: "Warmth"
			hint: "Lower is warmer."
			Range {
				from: 3000
				to: 6000
				step: 100
				value: Config.nightLight.temperature
				format: v => Math.round(v) + " K"
				onMoved: value => Config.set("nightLight", "temperature", Math.round(value / 100) * 100)
			}
		}

		SettingRow {
			label: "On a schedule"
			hint: `By itself from ${Config.nightLight.from} to ${Config.nightLight.to}.`
			Toggle {
				checked: Config.nightLight.schedule
				onToggled: checked => Config.set("nightLight", "schedule", checked)
			}
		}

		SettingRow {
			visible: Config.nightLight.schedule
			label: "From, to"
			hint: "24-hour times, and Enter."
			Row {
				spacing: 8

				TextField {
					width: 80
					text: Config.nightLight.from
					onAccepted: value => { if (/^\d{1,2}:\d{2}$/.test(value.trim())) Config.set("nightLight", "from", value.trim().padStart(5, "0")); }
				}

				TextField {
					width: 80
					text: Config.nightLight.to
					onAccepted: value => { if (/^\d{1,2}:\d{2}$/.test(value.trim())) Config.set("nightLight", "to", value.trim().padStart(5, "0")); }
				}
			}
		}
	}
}
