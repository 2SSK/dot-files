pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The power menu, a HangingPanel like the control center: the island widens and a row of tiles unfolds
// from it. Arrows or a click pick, Enter or a click runs (twice for Log Out, Reboot and Shut Down),
// 1–5 jump. The keys come through the compositor's "power" mode (Panel), on i3 and sway alike.
HangingPanel {
	id: root

	name: "power"
	open: Panel.powerOpen
	panelWidth: Panel.sizes.power.width
	panelHeight: Panel.sizes.power.height
	onDismissed: Panel.closePower()

	Column {
		anchors.fill: parent
		anchors.margins: 16
		anchors.topMargin: 14
		spacing: 10

		Item {
			id: tiles

			readonly property real tile: (width - 32) / 5

			width: parent.width
			height: 86

			Repeater {
				model: Panel.actions

				delegate: Rectangle {
					id: action

					required property var modelData
					required property int index

					readonly property bool armed: Panel.armed === index
					readonly property bool picked: Panel.selected === index

					x: index * (tiles.tile + 8)
					width: tiles.tile
					height: tiles.height
					radius: Theme.radiusPanel
					color: armed ? Theme.error : Theme.surface

					Behavior on color {
						ColorAnimation {
							duration: Theme.quick
							easing.type: Theme.curve
						}
					}

					Column {
						anchors.centerIn: parent
						spacing: 8

						Glyph {
							anchors.horizontalCenter: parent.horizontalCenter
							glyph: Icons.g(action.modelData.glyph)
							font.pixelSize: 25
							color: action.armed ? Theme.primaryText : action.picked ? Theme.primary : Theme.fg

							Behavior on color {
								ColorAnimation {
									duration: Theme.normal
									easing.type: Theme.curve
								}
							}
						}

						UiText {
							anchors.horizontalCenter: parent.horizontalCenter
							text: action.armed ? "Again" : action.modelData.label
							color: action.armed ? Theme.primaryText : Theme.fg
							font.pixelSize: Theme.textCaption
							font.weight: Font.Medium
						}
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Panel.activate(action.index)
					}
				}
			}

			// one highlight that slides to the picked tile (a tint and a thin edge; clicks pass through)
			Rectangle {
				x: Panel.selected * (tiles.tile + 8)
				width: tiles.tile
				height: tiles.height
				radius: Theme.radiusPanel
				color: Qt.alpha(Theme.primary, 0.14)
				border.width: 1
				border.color: Qt.alpha(Theme.primary, 0.26)
				opacity: Panel.armed >= 0 ? 0 : 1

				Behavior on x {
					enabled: root.progress === 1 // at the first tile from its first frame
					NumberAnimation {
						duration: Theme.normal
						easing.type: Easing.InOutCubic
					}
				}

				Behavior on opacity {
					NumberAnimation {
						duration: Theme.quick
						easing.type: Theme.curve
					}
				}
			}
		}

		UiText {
			text: Panel.armed >= 0 ? `Press again to ${Panel.actions[Panel.armed].label.toLowerCase()}.` : "← → pick  ·  Enter runs  ·  1–5 jump"
			color: Panel.armed >= 0 ? Theme.error : Theme.fgMuted
			font.pixelSize: Theme.textCaption
		}
	}
}
