pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.widgets

// The widgets named for one part of the bar (bar.left, bar.center, bar.right in shell.json). The
// static style separates them with a thin bar, as polybar did; on the island each sits in a soft
// capsule, as noctalia's (a widget can tint its own with a `capsule` colour).
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
			recorder: "RecorderButton"
		})

	vertical: Config.vertical
	spacing: Config.island ? 6 : 10

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

			Item {
				readonly property real pad: Config.island ? 10 : 0
				readonly property real thick: Config.bar.size - 8

				implicitWidth: Config.vertical ? (Config.island ? thick : widget.width) : widget.width + 2 * pad
				implicitHeight: Config.vertical ? widget.height + 2 * pad : Config.island ? thick : widget.height

				Rectangle {
					visible: Config.island
					anchors.fill: parent
					radius: Math.min(width, height) / 2
					color: widget.item?.capsule ?? Qt.alpha(Theme.surface, 0.9)
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
