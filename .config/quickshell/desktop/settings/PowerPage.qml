pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → Power: The power menu, what idle does, and the battery (low warning and charge limit).
Column {
	id: page

	spacing: 22

	Component.onCompleted: Power.refresh() // the charge limit, as the battery has it now

	Section {
		title: "Power menu"

		SettingRow {
			label: "Confirm"
			hint: "Log Out, Reboot and Shut Down need a second press."
			Toggle {
				checked: Config.power.confirm
				onToggled: checked => Config.set("power", "confirm", checked)
			}
		}
	}

	Section {
		title: "When idle"

		Repeater {
			model: [
				{ key: "dim", label: "Dim the screen", hint: "Any key or movement brings it back." },
				{ key: "lock", label: "Lock", hint: "The laptop keeps running." },
				{ key: "off", label: "Switch the screen off", hint: "Even while locked." }
			]

			delegate: SettingRow {
				id: idleRow

				required property var modelData

				label: modelData.label
				hint: modelData.hint
				Range {
					from: 0
					to: 30
					step: 1
					value: Config.idle[idleRow.modelData.key]
					format: v => Math.round(v) === 0 ? "Never" : Math.round(v) + " min"
					onMoved: value => Config.set("idle", idleRow.modelData.key, Math.round(value))
				}
			}
		}
	}

	Section {
		title: "Battery"

		SettingRow {
			label: "Low battery"
			hint: "At or below this, the battery turns red and a notification warns you (again at 10%)."
			Range {
				from: 10
				to: 50
				step: 1
				value: Config.power.batteryLow
				format: v => Math.round(v) + " %"
				onMoved: value => Config.set("power", "batteryLow", Math.round(value))
			}
		}

		// TLP keeps it (desktop-power): not a shell setting. Shown as dragged, applied once let go
		SettingRow {
			visible: Power.limit > 0
			label: "Charge limit"
			hint: "Charging stops here (80% by default; some ASUS laptops only keep 40, 60 or 80): a battery kept below full lasts longer. 100% before a trip."
			Range {
				id: chargeLimit

				property int dragged: 0 // while dragging; 0 shows the battery's own

				from: 50
				to: 100
				step: 5
				value: dragged || Power.limit
				format: v => Math.round(v) + " %"
				onMoved: value => dragged = Math.round(value)
				onReleased: value => {
					if (dragged && dragged !== Power.limit)
						Power.setLimit(dragged);
					dragged = 0;
				}
			}
		}
	}
}
