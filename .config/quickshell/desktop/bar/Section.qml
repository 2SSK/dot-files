pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.widgets

// The widgets named for one part of the bar in shell.json. With capsules (bar.capsules) the island
// holds each part in one round pill, the static bar each widget in a soft chip; without them the
// static style separates them with a thin bar, as polybar did. `length` stretches the part (the
// island's two sides match), and `alert` swaps its widgets for a warning in its place.
Item {
	id: root

	property var names: []
	property ShellScreen screen: null
	property real length: 0 // at least this along the bar
	property string alertGlyph: "" // a warning in the widgets' place while set (the island's end)
	property string alertText: ""
	property bool alertCrit: false

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
	readonly property bool vertical: Config.vertical
	readonly property bool pill: Config.island && Config.bar.capsules
	readonly property bool chips: !Config.island && Config.bar.capsules
	readonly property bool alert: alertGlyph !== ""
	readonly property real thick: Config.bar.size - 2 * Theme.barInset
	// the island's clock fills its pill to the edge; other parts keep their ends clear
	readonly property real pad: pill ? (slots.count === 1 && slots.itemAt(0)?.flush ? 0 : 14) : 0
	readonly property real contentLength: vertical ? line.implicitHeight : line.implicitWidth
	readonly property real alertLength: alert ? (vertical ? warning.implicitHeight : warning.implicitWidth) : 0
	// what this part needs, before any stretching
	readonly property real natural: line.shown.length === 0 && !alert ? 0 : Math.max(contentLength, alertLength) + 2 * pad
	readonly property real along: natural > 0 ? Math.max(natural, length) : 0

	implicitWidth: vertical ? (pill ? thick : line.implicitWidth) : along
	implicitHeight: vertical ? along : pill ? thick : line.implicitHeight
	width: implicitWidth
	height: implicitHeight

	Rectangle {
		visible: root.pill && root.natural > 0
		anchors.fill: parent
		radius: Math.min(width, height) / 2
		color: root.alert ? (root.alertCrit ? Theme.error : Theme.warning) : Qt.alpha(Theme.fg, 0.08)

		Behavior on color {
			ColorAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}
	}

	Line {
		id: line

		anchors.centerIn: parent
		anchors.verticalCenterOffset: root.alert ? 5 : 0
		vertical: root.vertical
		spacing: root.chips ? Theme.barInset : root.pill ? 14 : Config.island ? 18 : 10
		opacity: root.alert ? 0 : 1
		enabled: !root.alert // its clicks go to the warning meanwhile

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on anchors.verticalCenterOffset {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Repeater {
			id: slots

			model: root.names

			delegate: Line {
				id: slot

				required property string modelData
				required property int index

				readonly property bool present: widget.item?.present ?? true
				readonly property bool flush: widget.item?.flush ?? false
				// a present widget somewhere before this one, which the separator divides it from
				readonly property bool follows: {
					for (let i = 0; i < index; i++)
						if (slots.itemAt(i)?.present)
							return true;
					return false;
				}

				visible: present // a missing battery or backlight leaves no gap
				vertical: root.vertical
				spacing: line.spacing

				Label {
					font.family: Theme.fontBar
					visible: !Config.island && !Config.bar.capsules && slot.present && slot.follows
					text: root.vertical ? "—" : "|"
					color: Theme.border
					font.weight: Theme.barWeight
				}

				Item {
					// a chip of its own on the static bar, unless the widget draws its own (workspaces)
					readonly property bool chip: root.chips && !(widget.item?.ownCapsule ?? false)

					implicitWidth: root.vertical ? (chip ? root.thick : widget.width) : widget.width + (chip ? 24 : 0)
					implicitHeight: root.vertical ? widget.height + (chip ? 24 : 0) : chip ? root.thick : widget.height

					Rectangle {
						visible: parent.chip
						anchors.fill: parent
						radius: Theme.radiusSmall
						color: widget.item?.capsule ?? Qt.alpha(Theme.fg, 0.08)
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

	// the warning, dark on its colour
	Grid {
		id: warning

		anchors.centerIn: parent
		anchors.verticalCenterOffset: root.alert ? 0 : -5
		columns: root.vertical ? 1 : 2
		spacing: root.vertical ? 2 : 6
		horizontalItemAlignment: Grid.AlignHCenter
		verticalItemAlignment: Grid.AlignVCenter
		opacity: root.alert ? 1 : 0
		visible: opacity > 0

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on anchors.verticalCenterOffset {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Glyph {
			glyph: root.alertGlyph
			color: root.pill ? Theme.bg : root.alertCrit ? Theme.error : Theme.warning
		}

		Label {
			text: root.alertText
			color: root.pill ? Theme.bg : root.alertCrit ? Theme.error : Theme.warning
			font.family: Theme.fontBar
			font.weight: Theme.barWeight
			font.pixelSize: root.vertical ? Theme.fontSize - 3 : Theme.fontSize
		}
	}
}
