import QtQuick
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → Popups: Notification popups: where and how long they show.
Column {
	id: page

	spacing: 22

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
}
