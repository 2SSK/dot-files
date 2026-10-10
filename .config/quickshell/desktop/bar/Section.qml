pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.widgets

// The widgets named for one part of the bar (bar.left, bar.center, bar.right in shell.json). Each
// sits in a soft capsule (bar.capsules; a widget may tint its own with a `capsule` colour); without
// capsules the static style separates them with a thin bar, as polybar did.
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
			notifications: "NotificationButton",
			scratchpad: "ScratchpadButton",
			controls: "ControlButton",
			wifi: "WifiButton",
			bluetooth: "BluetoothButton",
			notes: "NotesButton",
			todo: "TodoButton",
			tools: "Tools",
			clipboard: "ClipboardButton"
		})

	vertical: Config.vertical
	spacing: Config.bar.capsules ? Theme.barInset : Config.island ? 18 : 10

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

			Label {
				font.family: Theme.fontBar
				visible: !Config.island && !Config.bar.capsules && slot.present && slot.follows
				text: Config.vertical ? "—" : "|"
				color: Theme.border
				font.weight: Theme.barWeight
			}

			Item {
				readonly property bool capsule: Config.bar.capsules
				readonly property real thick: Config.bar.size - 2 * Theme.barInset

				implicitWidth: Config.vertical ? (capsule ? thick : widget.width) : widget.width + (capsule ? 24 : 0)
				implicitHeight: Config.vertical ? widget.height + (capsule ? 24 : 0) : capsule ? thick : widget.height

				Rectangle {
					visible: parent.capsule
					anchors.fill: parent
					radius: Math.min(width, height) / 2
					color: widget.item?.capsule ?? Qt.alpha(Theme.surface, 0.85)
				}

				Loader {
					id: widget

					anchors.centerIn: parent
					source: root.files[slot.modelData] ? Qt.resolvedUrl(`../widgets/${root.files[slot.modelData]}.qml`) : ""
					// widgets that care which screen they're on (workspaces) get it
					onLoaded: if ("screen" in item) item.screen = Qt.binding(() => root.screen)
				}
			}
		}
	}
}
