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

	property string family: "" // what the buttons show: the choice, at once
	property string mode: ""
	property var families: []
	property string applied: "" // "family mode" the last switch made (or being made)

	// a click shows at once; the switch (render, then reload every app) runs behind, one at a time:
	// clicks made meanwhile only change what runs next, so a burst ends on the last choice
	function choose(family: string, mode: string): void {
		page.family = family;
		page.mode = mode;
		if (!apply.running)
			run();
	}

	function run(): void {
		applied = `${family} ${mode}`;
		apply.command = ["theme", "set", family, "--mode", mode];
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
		running: true
		command: ["theme", "current"]
		stdout: StdioCollector {
			onStreamFinished: {
				const [family, mode] = text.trim().split(" ");
				page.family = family;
				page.mode = mode;
				page.applied = `${family} ${mode}`;
			}
		}
	}

	Process {
		id: apply

		// a newer choice came in while this one ran: switch to it now
		onExited: if (`${page.family} ${page.mode}` !== page.applied) page.run()
	}

	Section {
		title: "Theme"

		SettingRow {
			label: "Mode"
			Choice {
				options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]
				value: page.mode
				onPicked: value => page.choose(page.family, value)
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

					Behavior on color {
						ColorAnimation {
							duration: 160
						}
					}

					Text {
						anchors.centerIn: parent
						text: swatch.modelData
						color: swatch.on ? Theme.primaryText : Theme.fg

						Behavior on color {
							ColorAnimation {
								duration: 160
							}
						}
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textBody
						font.weight: Font.Medium
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: page.choose(swatch.modelData, page.mode)
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

	Section {
		title: "Fonts"

		FontRow {
			label: "Interface"
			hint: "Most of the shell's text."
			value: Theme.fontSans
			onPicked: family => Config.set("fonts", "sans", family)
		}

		FontRow {
			label: "Headings"
			hint: "Titles, tile names, the clock and other semibold text."
			value: Theme.fontHeading
			onPicked: family => Config.set("fonts", "heading", family)
		}

		FontRow {
			label: "Bar"
			hint: "The clock, figures and labels on the bar."
			value: Theme.fontBar
			onPicked: family => Config.set("fonts", "bar", family)
		}

		FontRow {
			label: "Code"
			hint: "The clipboard's text, code notes."
			value: Theme.fontMono
			mono: true
			onPicked: family => Config.set("fonts", "mono", family)
		}

		SettingRow {
			label: "Weight"
			hint: "Of body text; headings keep theirs."
			Choice {
				options: [{ value: 400, label: "Regular" }, { value: 500, label: "Medium" }, { value: 600, label: "Semibold" }]
				value: Theme.textWeight
				onPicked: value => Config.set("fonts", "weight", value)
			}
		}

		SettingRow {
			label: "Size"
			hint: "115% reads like the terminal and GTK apps here."
			Range {
				from: 0.9
				to: 1.4
				step: 0.05
				value: Config.fonts.scale
				format: v => Math.round(v * 100) + " %"
				onMoved: value => Config.set("fonts", "scale", value)
			}
		}
	}

}
