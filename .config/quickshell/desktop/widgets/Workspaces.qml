pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services

// This screen's workspaces. Static: its five as chips in Roman numerals, always there:
// an accent that slides to where you are, a faint tint with windows, just a dim numeral when empty. Island:
// only those in use, as dots, the one showing a wide pill; a dot grows in as a workspace appears and
// shrinks away as it goes. An urgent one is red.
Line {
	id: root

	property ShellScreen screen: null // set by the bar
	readonly property var here: WindowManager.workspaces.filter(ws => ws.output === screen?.name)
	readonly property bool chips: !Config.island
	// the chips are capsules of their own (Section draws none round them)
	readonly property bool ownCapsule: chips && Config.bar.capsules
	readonly property real thick: Config.bar.size - 2 * Theme.barInset
	readonly property real dot: Math.round(Config.bar.size * 0.3)

	vertical: Config.vertical
	spacing: 8

	// ---- static: the chips, an accent sliding under them to the one showing
	// this screen's five: 6–10 on the laptop panel while a monitor has 1–5 (desktop displays), else
	// 1–5; and any other in use here, after them
	readonly property int first: here.length > 0 && Math.min(...here.map(ws => ws.num)) > 5 ? 6 : 1
	readonly property var numbers: [0, 1, 2, 3, 4].map(i => first + i).concat(here.map(ws => ws.num).filter(n => n < first || n > first + 4)).sort((a, b) => a - b)
	readonly property int showing: here.find(ws => ws.visible)?.num ?? 0
	readonly property var romans: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

	function roman(n: int): string {
		return romans[n] ?? String(n);
	}

	Item {
		visible: root.chips
		implicitWidth: chipRow.implicitWidth
		implicitHeight: chipRow.implicitHeight

		Rectangle {
			id: accent

			readonly property Item at: chipRepeater.count, chipRepeater.itemAt(root.numbers.indexOf(root.showing))

			visible: !!at
			x: at?.x ?? 0
			y: at?.y ?? 0
			width: at?.width ?? 0
			height: at?.height ?? 0
			radius: Theme.radiusSmall
			color: at?.workspace?.focused === false ? Qt.alpha(Theme.primary, 0.55) : Theme.primary

			Behavior on x {
				NumberAnimation {
					duration: Theme.normal
					easing.type: Theme.curve
				}
			}

			Behavior on y {
				NumberAnimation {
					duration: Theme.normal
					easing.type: Theme.curve
				}
			}
		}

		Line {
			id: chipRow

			vertical: root.vertical
			spacing: Theme.barInset

			Repeater {
				id: chipRepeater

				model: root.numbers

				delegate: Rectangle {
					id: chip

					required property int modelData
					readonly property var workspace: root.here.find(ws => ws.num === modelData) ?? WindowManager.workspaces.find(ws => ws.num === modelData)
					readonly property bool on: modelData === root.showing
					readonly property bool full: !!workspace && !on

					implicitWidth: root.vertical ? root.thick : Math.max(root.thick + 10, widestNumeral.width + 18)
					implicitHeight: root.thick
					radius: Theme.radiusSmall
					// with windows a faint tint of the text colour, empty just the dim numeral: right on any scheme
					color: workspace?.urgent && !on ? Theme.error : on ? "transparent" : Qt.alpha(Theme.fg, full ? (hover.containsMouse ? 0.16 : 0.08) : hover.containsMouse ? 0.06 : 0)

					Behavior on color {
						ColorAnimation {
							duration: Theme.normal
							easing.type: Theme.curve
						}
					}

					Column {
						id: numeral

						readonly property color tint: (chip.on && chip.workspace?.focused !== false) || chip.workspace?.urgent ? Theme.primaryText : chip.full ? Theme.fg : Qt.alpha(Theme.fg, 0.35)

						anchors.centerIn: parent

						UiText {
							id: label

							anchors.horizontalCenter: parent.horizontalCenter
							text: root.roman(chip.modelData)
							color: numeral.tint
							font.family: Theme.fontBar
							font.pixelSize: root.vertical ? Theme.fontSize - 5 : Theme.fontSize - 3
							font.weight: Font.Bold

							Behavior on color {
								ColorAnimation {
									duration: Theme.normal
									easing.type: Theme.curve
								}
							}
						}
					}

					MouseArea {
						id: hover

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: WindowManager.switchTo(chip.modelData)
					}
				}
			}
		}

		// every chip as wide as the widest numeral here
		TextMetrics {
			id: widestNumeral

			font.family: Theme.fontBar
			font.pixelSize: Theme.fontSize - 3
			font.weight: Font.Bold
			text: root.numbers.map(n => root.roman(n)).reduce((a, b) => b.length > a.length ? b : a, "")
		}
	}

	// ---- island: the dots, keyed by number so each keeps its delegate (and its animation)
	ListView {
		id: dots

		visible: !root.chips
		interactive: false
		orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
		implicitWidth: root.vertical ? root.dot : contentWidth
		implicitHeight: root.vertical ? contentHeight : root.dot
		width: implicitWidth
		height: implicitHeight
		model: ScriptModel {
			values: root.chips ? [] : root.here
			objectProp: "num"
		}

		delegate: Item {
			id: slot

			required property var modelData
			// the model keeps the first object it saw for a number; the live state is in `here`
			readonly property var workspace: root.here.find(ws => ws.num === modelData.num) ?? modelData
			readonly property bool shown: workspace.visible
			readonly property real long: shown ? root.dot * 2.5 : root.dot
			readonly property real gap: 7
			property real grow: 0 // 0 to 1 as it comes, back to 0 as it goes

			width: root.vertical ? root.dot : (long + gap) * grow
			height: root.vertical ? (long + gap) * grow : root.dot

			Component.onCompleted: grow = 1

			Behavior on grow {
				NumberAnimation {
					duration: Theme.slow
					easing.type: Theme.curve
				}
			}

			ListView.onRemove: leave.start()

			SequentialAnimation {
				id: leave

				PropertyAction {
					target: slot
					property: "ListView.delayRemove"
					value: true
				}

				NumberAnimation {
					target: slot
					property: "grow"
					to: 0
					duration: Theme.slow
					easing.type: Theme.curve
				}

				PropertyAction {
					target: slot
					property: "ListView.delayRemove"
					value: false
				}
			}

			Rectangle {
				anchors.centerIn: parent
				width: root.vertical ? root.dot : slot.long * slot.grow
				height: root.vertical ? slot.long * slot.grow : root.dot
				radius: root.dot / 2
				opacity: slot.grow
				color: slot.workspace.urgent ? Theme.error : slot.shown ? (slot.workspace.focused ? Theme.primary : Qt.alpha(Theme.primary, 0.55)) : hover.containsMouse ? Theme.fg : Qt.alpha(Theme.fg, 0.55)

				Behavior on width {
					enabled: slot.grow === 1
					NumberAnimation {
						duration: Theme.slow
						easing.type: Theme.curve
					}
				}

				Behavior on height {
					enabled: slot.grow === 1
					NumberAnimation {
						duration: Theme.slow
						easing.type: Theme.curve
					}
				}

				Behavior on color {
					ColorAnimation {
						duration: Theme.normal
						easing.type: Theme.curve
					}
				}
			}

			MouseArea {
				id: hover

				anchors.fill: parent
				anchors.margins: -3
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: WindowManager.switchTo(slot.modelData.num)
			}
		}
	}

	// i3's mode, where it changes what the keys do: keys passed through to a VM, or resizing
	Rectangle {
		readonly property string label: ({ passthrough: "VM keys", resize: "Resize" })[WindowManager.mode] ?? ""

		visible: label !== ""
		implicitWidth: modeLabel.implicitWidth + 16
		implicitHeight: Math.round(Config.bar.size * 0.5)
		radius: height / 2
		color: Theme.primary

		UiText {
			id: modeLabel

			anchors.centerIn: parent
			text: parent.label
			color: Theme.primaryText
			font.family: Theme.fontBar
			font.pixelSize: Theme.fontSize - 3
			font.weight: Theme.barWeight
		}
	}
}
