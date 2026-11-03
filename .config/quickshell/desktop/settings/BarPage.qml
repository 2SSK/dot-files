import QtQuick
import qs
import qs.services
import qs.widgets

// Settings → Bar: its look. The widgets are set in shell.json (bar.left, center, right): the design
// places them, so there's nothing to drag.
Column {
	id: page

	spacing: 24

	Section {
		title: "Look"

		SettingRow {
			label: "Style"
			hint: "Island floats as a pill; static fills the whole edge."
			Choice {
				options: [{ value: "island", label: "Island" }, { value: "static", label: "Static" }]
				value: Config.bar.style
				// each style with its own look: the island plain, the static bar in chips (toggle below)
				onPicked: value => {
					Config.set("bar", "style", value);
					Config.set("bar", "capsules", value === "static");
				}
			}
		}

		SettingRow {
			label: "Capsules"
			hint: "Round pills on the island, soft chips on the static bar."
			Toggle {
				checked: Config.bar.capsules
				onToggled: checked => Config.set("bar", "capsules", checked)
			}
		}

		SettingRow {
			label: "Position"
			hint: Config.wayland ? "" : "i3 docks bars only at the top or bottom."
			Choice {
				options: (Config.wayland ? ["top", "bottom", "left", "right"] : ["top", "bottom"]).map(p => ({ value: p, label: p[0].toUpperCase() + p.slice(1) }))
				value: Config.bar.position
				onPicked: value => Config.set("bar", "position", value)
			}
		}

		SettingRow {
			label: "Height"
			Range {
				from: 26
				to: 48
				step: 1
				value: Config.bar.size
				format: v => Math.round(v) + " px"
				onMoved: value => Config.set("bar", "size", Math.round(value))
			}
		}

		SettingRow {
			label: "Opacity"
			Range {
				from: 0.4
				to: 1
				step: 0.05
				value: Config.bar.opacity
				format: v => Math.round(v * 100) + " %"
				onMoved: value => Config.set("bar", "opacity", value)
			}
		}
	}
}
