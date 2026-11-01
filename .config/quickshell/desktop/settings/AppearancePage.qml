pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs
import qs.services
import qs.widgets

// Settings → Appearance: the theme (family and dark or light, through the theme command) and the night light.
Column {
	id: page

	spacing: 22

	property string family: ""
	property string mode: ""
	property var families: []
	property string applied: "" // "family mode" the last switch made (or being made)

	// the switch (render, then reload every app) runs one at a time, so a burst of clicks ends on the last
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

	// each family with its palettes, for cards drawn in the theme's own colours
	Process {
		running: true
		command: ["theme", "list", "--json"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					page.families = JSON.parse(text);
				} catch (e) {
					page.families = [];
				}
			}
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

				// a card in the theme's own colours (this mode's, else dark's): its background, a row of its
				// accents and its name; the chosen one ringed in the current accent, with a tick
				delegate: Rectangle {
					id: swatch

					required property var modelData
					readonly property bool on: page.family === modelData.family
					readonly property var ui: modelData[page.mode] ?? modelData.dark ?? {}

					width: 168
					height: 84
					radius: 14
					color: ui.bg ?? Theme.surface
					border.width: on ? 2 : 1
					border.color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.35) : Qt.alpha(Theme.border, 0.7)

					Behavior on border.color {
						ColorAnimation {
							duration: Theme.quick
							easing.type: Theme.curve
						}
					}

					Row {
						x: 14
						y: 14
						spacing: 6

						Repeater {
							model: [swatch.ui.primary, swatch.ui.secondary, swatch.ui.accent, swatch.ui.success, swatch.ui.error]

							Rectangle {
								required property var modelData

								width: 14
								height: 14
								radius: 7
								color: modelData ?? "transparent"
							}
						}
					}

					// a sample line of its text on its surface
					Rectangle {
						x: 14
						y: 38
						width: parent.width - 28
						height: 8
						radius: 4
						color: swatch.ui.surface ?? "transparent"

						Rectangle {
							width: parent.width * 0.55
							height: parent.height
							radius: 4
							color: Qt.alpha(swatch.ui.fg_muted ?? "transparent", 0.6)
						}
					}

					UiText {
						x: 14
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 10
						text: swatch.modelData.name ?? swatch.modelData.family
						color: swatch.ui.fg ?? Theme.fg
						font.weight: Font.DemiBold
						font.pixelSize: Theme.textLabel
					}

					Rectangle {
						visible: swatch.on
						anchors.right: parent.right
						anchors.rightMargin: 10
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 10
						width: 20
						height: 20
						radius: 10
						color: Theme.primary

						Glyph {
							anchors.centerIn: parent
							glyph: Icons.g("check")
							color: Theme.primaryText
							font.pixelSize: 12
						}
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: page.choose(swatch.modelData.family, page.mode)
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

		SettingRow {
			label: "Bar weight"
			Choice {
				options: [{ value: 500, label: "Medium" }, { value: 600, label: "Semibold" }]
				value: Theme.barWeight
				onPicked: value => Config.set("fonts", "barWeight", value)
			}
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
