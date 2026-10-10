import QtQuick
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → Bar: The bar: its look, and its widgets in the three parts.
Column {
	id: page

	spacing: 22

	Section {
		title: "Look"

		SettingRow {
			label: "Style"
			hint: "Island floats as a pill; static fills the whole edge."
			Choice {
				options: [{ value: "island", label: "Island" }, { value: "static", label: "Static" }]
				value: Config.bar.style
				onPicked: value => Config.set("bar", "style", value)
			}
		}

		SettingRow {
			label: "Capsules"
			hint: "Each widget in a soft capsule."
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

		SettingRow {
			visible: Config.island
			label: "Island width"
			hint: Config.bar.length > 0 ? "A fixed share of the screen edge." : "Follows the screen: more of a narrow one, less of a wide one."
			Row {
				spacing: 14

				Toggle {
					anchors.verticalCenter: parent.verticalCenter
					checked: Config.bar.length === 0
					onToggled: checked => Config.set("bar", "length", checked ? 0 : 0.55)
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: "Auto"
					color: Theme.fg
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: 14
				}

				Range {
					visible: Config.bar.length > 0
					from: 0.3
					to: 0.95
					step: 0.05
					value: Config.bar.length
					format: v => Math.round(v * 100) + " %"
					onMoved: value => Config.set("bar", "length", value)
				}
			}
		}
	}

	Section {
		title: "Widgets"

		WidgetLayout {}
	}
}
