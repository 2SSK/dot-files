pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The power menu, a row of tiles under the bar. Arrows or the mouse pick, Enter or a click runs (twice
// for Log Out, Reboot and Shut Down), 1–5 jump; i3's "power" mode hands it the keys.
PopupWindow {
	id: root

	required property PanelWindow bar
	required property Item island

	readonly property bool open: Panel.view === "power" && WindowManager.focusedOutput === bar.screen?.name
	readonly property string position: Config.position
	readonly property real reach: Panel.barShown ? (Config.vertical ? bar.width : bar.height) : 0
	// mapped while open (see Osd)
	property bool shown: false

	onOpenChanged: open ? shown = true : hide.restart()

	Timer {
		id: hide

		interval: 260
		onTriggered: if (!root.open) root.shown = false
	}

	// the whole screen, so a click beside the tiles closes the menu
	anchor.window: bar
	anchor.rect.x: position === "right" ? bar.width - implicitWidth : 0
	anchor.rect.y: position === "bottom" ? bar.height - implicitHeight : 0
	implicitWidth: bar.screen.width
	implicitHeight: bar.screen.height
	visible: shown
	color: "transparent"

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: Panel.closePower()
	}

	Row {
		id: tiles

		x: root.position === "left" ? root.reach + 12 : root.position === "right" ? root.width - root.reach - 12 - width : (root.width - width) / 2
		y: (root.position === "top" ? root.reach + 12 : root.position === "bottom" ? root.height - root.reach - 12 - height : (root.height - height) / 2) + (root.open ? 0 : -12)
		spacing: 10
		opacity: root.open ? 1 : 0

		Behavior on y {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Repeater {
			model: Panel.actions

			delegate: Item {
				id: tile

				required property var modelData
				required property int index

				readonly property bool selected: Panel.selected === index
				readonly property bool armed: Panel.armed === index
				readonly property color ink: armed || selected ? Theme.primaryText : Theme.fg

				width: 170
				height: 118

				Shadow {
					anchors.fill: face
					radius: face.radius
					blur: 20
					offsetY: 4
					color: Qt.alpha("black", 0.4)
				}

				Rectangle {
					id: face

					anchors.fill: parent
					radius: 14
					color: tile.armed ? Theme.error : tile.selected ? Theme.primary : Qt.alpha(Theme.bg, 0.96)
					border.width: 1
					border.color: tile.armed ? Theme.error : tile.selected ? Theme.primary : Qt.alpha(Theme.border, 0.8)

					Behavior on color {
						ColorAnimation {
							duration: Theme.quick
							easing.type: Theme.curve
						}
					}
				}

				Column {
					anchors.centerIn: parent
					spacing: 12

					Glyph {
						anchors.horizontalCenter: parent.horizontalCenter
						glyph: tile.modelData.glyph
						font.pixelSize: 30
						font.weight: Font.Normal
						color: tile.ink
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: tile.armed ? "Again to " + tile.modelData.label.toLowerCase() : tile.modelData.label
						color: tile.ink
						font.pixelSize: Theme.px(15)
						font.weight: Font.Medium
					}
				}

				Rectangle {
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.margins: 8
					width: 18
					height: 18
					radius: 4
					color: tile.armed || tile.selected ? Qt.alpha(Theme.primaryText, 0.2) : Qt.alpha(Theme.overlay, 0.9)

					UiText {
						anchors.centerIn: parent
						text: tile.index + 1
						color: tile.ink
						font.family: Theme.fontMono
						font.pixelSize: Theme.textCaption
						font.weight: Font.Bold
					}
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onEntered: if (Panel.selected !== tile.index) Panel.move(tile.index - Panel.selected)
					onClicked: Panel.activate(tile.index)
				}
			}
		}
	}
}
