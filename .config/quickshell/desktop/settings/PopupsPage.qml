import QtQuick
import qs
import qs.services
import qs.widgets

// Settings → Notifications: how long popups stay, and the calendar's heads-up before events and its
// next-up in the bar.
Column {
	id: page

	spacing: 24

	Section {
		title: "Popups"

		SettingRow {
			label: "Do Not Disturb"
			hint: "Only critical notifications pop up; all of them reach the history."
			Toggle {
				checked: Notifications.dnd
				onToggled: checked => Notifications.dnd = checked
			}
		}

		SettingRow {
			label: "Time on screen"
			hint: "How long a popup stays, unless the app asks for its own time."
			Range {
				from: 2000
				to: 15000
				step: 500
				value: Config.notifications.timeout
				format: v => (v / 1000).toFixed(1) + " s"
				onMoved: value => Config.set("notifications", "timeout", Math.round(value))
			}
		}
	}

	Section {
		title: "Calendar"

		SettingRow {
			label: "Heads-up"
			hint: "A notification this long before each timed event, as well as at its time."
			Choice {
				options: [{ value: 0, label: "Off" }, { value: 5, label: "5 min" }, { value: 10, label: "10 min" }, { value: 15, label: "15 min" }]
				value: Config.calendar.lead
				onPicked: value => Config.set("calendar", "lead", value)
			}
		}

		SettingRow {
			label: "Next up in the bar"
			hint: "The clock names the next event this long before it starts."
			Choice {
				options: [{ value: 0, label: "Off" }, { value: 10, label: "10 min" }, { value: 15, label: "15 min" }, { value: 30, label: "30 min" }]
				value: Config.calendar.nextUp
				onPicked: value => Config.set("calendar", "nextUp", value)
			}
		}
	}
}
