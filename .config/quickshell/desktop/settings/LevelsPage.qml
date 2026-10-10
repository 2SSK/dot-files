import QtQuick
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → Levels: Volume and brightness: their steps and the on-screen display.
Column {
	id: page

	spacing: 22

	Section {
		title: "Volume and brightness"

		SettingRow {
			label: "Volume step"
			hint: "Per key press or scroll."
			Range {
				from: 1
				to: 20
				step: 1
				value: Config.audio.step
				format: v => Math.round(v) + " %"
				onMoved: value => Config.set("audio", "step", Math.round(value))
			}
		}

		SettingRow {
			label: "Brightness step"
			Range {
				from: 1
				to: 20
				step: 1
				value: Config.brightness.step
				format: v => Math.round(v) + " %"
				onMoved: value => Config.set("brightness", "step", Math.round(value))
			}
		}

		SettingRow {
			label: "Level card on screen"
			hint: "How long the card at the top right stays after a change."
			Range {
				from: 800
				to: 5000
				step: 100
				value: Config.osd.timeout
				format: v => (v / 1000).toFixed(1) + " s"
				onMoved: value => Config.set("osd", "timeout", Math.round(value))
			}
		}
	}
}
