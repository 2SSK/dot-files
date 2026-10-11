pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.widgets

// A wallpaper in the picker's grid: the picture with rounded corners, its name on hover, a ring and
// a tick on the one set, a thinner ring on the one picked with the keys.
Item {
	id: tile

	required property string modelData
	required property int index
	readonly property bool on: Wallpaper.current === modelData
	property bool picked // the one Enter sets (the keys' pick)
	property string label // its name, shown on hover or when picked while searching
	property bool searching
	signal chosen

	width: GridView.view.cellWidth
	height: GridView.view.cellHeight

	Item {
		id: frame

		anchors.fill: parent
		anchors.margins: 6
		scale: hover.hovered ? 1.03 : 1

		Behavior on scale {
			NumberAnimation {
				duration: 160
				easing.type: Easing.OutCubic
			}
		}

		Image {
			id: picture

			anchors.fill: parent
			visible: false
			source: "file://" + tile.modelData
			sourceSize.width: 360
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			cache: true
		}

		Rectangle {
			id: corners

			anchors.fill: parent
			visible: false
			layer.enabled: true
			radius: 12
		}

		Rectangle {
			anchors.fill: parent
			radius: 12
			color: Qt.alpha(Theme.surface, 0.8)
		}

		MultiEffect {
			anchors.fill: parent
			source: picture
			maskEnabled: true
			maskSource: corners
		}

		UiText {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.margins: 10
			text: tile.label
			elide: Text.ElideRight
			color: "white"
			font.family: Theme.fontHeading
			font.pixelSize: Theme.textLabel
			font.weight: Font.DemiBold
			opacity: hover.hovered || tile.picked && tile.searching ? 1 : 0
			layer.enabled: true
			layer.effect: MultiEffect {
				shadowEnabled: true
				shadowColor: "black"
				shadowOpacity: 0.8
				shadowBlur: 0.6
				shadowVerticalOffset: 1
				shadowHorizontalOffset: 0
			}

			Behavior on opacity {
				NumberAnimation {
					duration: 150
				}
			}
		}

		Rectangle {
			anchors.fill: parent
			anchors.margins: -3
			radius: 15
			color: "transparent"
			border.width: tile.on ? 3 : tile.picked ? 2 : 0
			border.color: tile.on ? Theme.primary : Qt.alpha(Theme.fg, 0.6)

			Behavior on border.width {
				NumberAnimation {
					duration: 160
				}
			}
		}

		Rectangle {
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.margins: 8
			width: 24
			height: 24
			radius: 12
			color: Theme.primary
			scale: tile.on ? 1 : 0

			Behavior on scale {
				NumberAnimation {
					duration: 220
					easing.type: Easing.OutBack
				}
			}

			Glyph {
				anchors.centerIn: parent
				glyph: Icons.g("check")
				font.pixelSize: 14
				color: Theme.primaryText
			}
		}
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: tile.chosen()
	}
}
