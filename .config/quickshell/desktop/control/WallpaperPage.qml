pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.settings
import qs.widgets

// Wallpapers: a click sets one; the header shuffles. Rotation: a new one every 5 minutes, hour or
// day, or each boot. The folders are wallpaper.folders in shell.json.
Column {
	id: root

	readonly property string title: "Wallpaper"
	readonly property var actions: [{ glyph: Icons.g("arrows-shuffle"), on: false, act: () => Wallpaper.shuffle(), show: Wallpaper.files.length > 1 }]

	spacing: 12

	Choice {
		width: parent.width
		options: [{ value: "off", label: "Fixed" }, { value: "5m", label: "5 min" }, { value: "1h", label: "Hourly" }, { value: "1d", label: "Daily" }, { value: "boot", label: "Each boot" }]
		value: Config.wallpaper.rotate
		onPicked: value => {
			Config.wallpaper.rotate = value;
			Config.save();
		}
	}

	Text {
		visible: Wallpaper.files.length === 0
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: "No images in " + Wallpaper.folders.join(", ")
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	// only what's on screen is loaded
	GridView {
		id: grid

		width: parent.width
		height: 480
		clip: true
		cellWidth: width / 3
		cellHeight: cellWidth * 0.64
		model: Wallpaper.files
		boundsBehavior: Flickable.StopAtBounds

		delegate: Item {
			id: tile

			required property string modelData
			readonly property bool on: Wallpaper.current === modelData

			width: grid.cellWidth
			height: grid.cellHeight

			Rectangle {
				anchors.fill: parent
				anchors.margins: 5
				radius: 12
				color: Qt.alpha(Theme.surface, 0.8)
				border.width: tile.on ? 3 : 0
				border.color: Theme.primary

				// the picture, its corners rounded by a mask
				Image {
					id: picture

					anchors.fill: parent
					anchors.margins: tile.on ? 3 : 0
					visible: false
					source: "file://" + tile.modelData
					sourceSize.width: 320
					fillMode: Image.PreserveAspectCrop
					asynchronous: true
					cache: true
				}

				Rectangle {
					id: corners

					anchors.fill: picture
					visible: false
					layer.enabled: true
					radius: tile.on ? 9 : 12
				}

				MultiEffect {
					anchors.fill: picture
					source: picture
					maskEnabled: true
					maskSource: corners
					opacity: picture.status === Image.Ready ? (hover.hovered || tile.on ? 1 : 0.85) : 0

					Behavior on opacity {
						NumberAnimation {
							duration: 150
						}
					}
				}

				Glyph {
					visible: tile.on
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					anchors.margins: 8
					glyph: Icons.g("check")
					filled: true
					font.pixelSize: 18
					color: Theme.primary
				}

				HoverHandler {
					id: hover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: Wallpaper.set(tile.modelData)
				}
			}
		}
	}
}
