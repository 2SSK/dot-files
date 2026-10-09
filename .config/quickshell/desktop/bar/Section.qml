pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.widgets

// The widgets named for one part of the bar (bar.left, bar.center, bar.right in shell.json). The
// static style separates them with a thin bar, as polybar did.
Line {
	id: root

	property var names: []
	property ShellScreen screen: null
	readonly property var files: ({
			launcher: "Launcher",
			workspaces: "Workspaces",
			clock: "Clock",
			stats: "SystemStats",
			volume: "VolumeLevel",
			brightness: "BrightnessLevel",
			battery: "BatteryLevel",
			tray: "Tray",
			power: "PowerButton",
			recorder: "RecorderButton",
			notifications: "NotificationButton"
		})

	vertical: Config.vertical
	spacing: Config.island ? 18 : 10

	Repeater {
		id: slots

		model: root.names

		delegate: Line {
			id: slot

			required property string modelData
			required property int index

			readonly property bool present: widget.item?.present ?? true
			// a present widget somewhere before this one, which the separator divides it from
			readonly property bool follows: {
				for (let i = 0; i < index; i++)
					if (slots.itemAt(i)?.present)
						return true;
				return false;
			}

			visible: present // a missing battery or backlight leaves no gap
			vertical: Config.vertical
			spacing: root.spacing

			Glyph {
				visible: !Config.island && slot.present && slot.follows
				text: Config.vertical ? "—" : "|"
				color: Theme.border
				font.weight: Font.Normal
			}

			Loader {
				id: widget

				source: root.files[slot.modelData] ? Qt.resolvedUrl(`../widgets/${root.files[slot.modelData]}.qml`) : ""
				// widgets that care which screen they're on (workspaces) get it
				onLoaded: if ("screen" in item) item.screen = Qt.binding(() => root.screen)
			}
		}
	}
}
