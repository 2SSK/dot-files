pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.control
import qs.services
import qs.widgets

// Wallpapers, dropping out of the bar (a HangingPanel). Type to search by name; ↑ ↓ move, Enter
// sets one, a click too; the desktop fades over to it. The first chip shows the current theme's
// folder (~/Wallpaper-Bank/<theme>/, the default) or all of them. The rotate chip picks how often a
// new one comes (never, 5 minutes, hourly, daily, each boot); shuffle sets one at random.
HangingPanel {
	id: root

	readonly property var rotations: [
		{ value: "off", label: "Never" },
		{ value: "5m", label: "Every 5 min" },
		{ value: "1h", label: "Hourly" },
		{ value: "1d", label: "Daily" },
		{ value: "boot", label: "Each boot" }
	]
	// the current theme's folder (when it has wallpapers), or all of them
	property bool all: Wallpaper.themeFiles.length === 0
	readonly property var shown: {
		const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
		return (all ? Wallpaper.files : Wallpaper.themeFiles).filter(f => {
			const name = f.slice(f.lastIndexOf("/") + 1).toLowerCase();
			return words.every(w => name.includes(w));
		});
	}
	property int current: Math.max(0, shown.indexOf(Wallpaper.current))

	function label(path: string): string {
		return path.slice(path.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ");
	}

	name: "wallpaper"
	open: Panel.wallpaperOpen
	panelWidth: Panel.wallpaperWidth
	panelHeight: Panel.wallpaperHeight
	onDismissed: Panel.wallpaperOpen = false
	onShownChanged: current = Math.max(0, Math.min(current, shown.length - 1))

	// search, rotate, shuffle, close
	Row {
		id: header

		x: 16
		y: 16
		width: parent.width - 32
		spacing: 8

		TextField {
			id: search

			width: parent.width - scope.width - rotate.width - buttons.width - 24
			height: 38
			placeholder: "Search wallpapers"
			Component.onCompleted: focusField()
			onAccepted: Wallpaper.set(root.shown[root.current] ?? "")
			onTextChanged: root.current = 0
			Keys.onUpPressed: grid.moveCurrentIndexUp()
			Keys.onDownPressed: grid.moveCurrentIndexDown()
			Keys.onTabPressed: grid.moveCurrentIndexRight()
			Keys.onBacktabPressed: grid.moveCurrentIndexLeft()
		}

		// the theme's folder or all of them
		Chip {
			id: scope

			anchors.verticalCenter: parent.verticalCenter
			height: 38
			visible: Wallpaper.themeFiles.length > 0
			glyph: Icons.g(root.all ? "photo" : "palette")
			label: root.all ? "All" : (Theme.palette.meta?.name ?? "Theme")
			onClicked: {
				root.all = !root.all;
				search.focusField();
			}
		}

		// how often a new one comes; a click opens the choices
		Rectangle {
			id: rotate

			readonly property bool on: Config.wallpaper.rotate !== "off"

			width: rotateRow.implicitWidth + 26
			height: 38
			radius: 11
			color: menu.open ? Qt.alpha(Theme.fg, 0.1) : rotateHover.hovered ? Qt.alpha(Theme.fg, 0.08) : Qt.alpha(Theme.surface, 0.7)
			border.width: 1
			border.color: rotate.on ? Qt.alpha(Theme.primary, 0.7) : Qt.alpha(Theme.border, 0.7)

			Row {
				id: rotateRow

				anchors.centerIn: parent
				spacing: 7

				Glyph {
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g("refresh")
					font.pixelSize: 14
					color: rotate.on ? Theme.primary : Theme.fgMuted
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: (root.rotations.find(r => r.value === Config.wallpaper.rotate) ?? root.rotations[0]).label
					color: rotate.on ? Theme.fg : Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 13
				}

				Glyph {
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g("chevron-down")
					font.pixelSize: 12
					color: Theme.fgMuted
					rotation: menu.open ? 180 : 0

					Behavior on rotation {
						NumberAnimation {
							duration: 180
							easing.type: Easing.OutCubic
						}
					}
				}
			}

			HoverHandler {
				id: rotateHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: menu.open = !menu.open
			}
		}

		Row {
			id: buttons

			spacing: 8

			Repeater {
				model: [
					{ glyph: Icons.g("arrows-shuffle"), act: () => Wallpaper.shuffle() },
					{ glyph: Icons.g("x"), act: () => Panel.wallpaperOpen = false }
				]

				delegate: Rectangle {
					id: button

					required property var modelData

					width: 38
					height: 38
					radius: 11
					color: buttonHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.7)
					border.width: 1
					border.color: Qt.alpha(Theme.border, 0.7)

					Glyph {
						anchors.centerIn: parent
						glyph: button.modelData.glyph
						font.pixelSize: 15
						font.weight: Font.Normal
					}

					HoverHandler {
						id: buttonHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: button.modelData.act()
					}
				}
			}
		}
	}

	// only what's on screen is loaded
	GridView {
		id: grid

		ScrollBoost {}

		x: 10
		y: header.y + header.height + 10
		width: parent.width - 20
		height: parent.height - y - 10
		clip: true
		cellWidth: width / 3
		cellHeight: Math.round(cellWidth * 0.62)
		model: root.shown
		currentIndex: root.current
		onCurrentIndexChanged: root.current = currentIndex
		keyNavigationWraps: true
		highlightFollowsCurrentItem: false
		boundsBehavior: Flickable.StopAtBounds

		delegate: Item {
			id: tile

			required property string modelData
			required property int index
			readonly property bool on: Wallpaper.current === modelData
			readonly property bool picked: root.current === index

			width: grid.cellWidth
			height: grid.cellHeight

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

				// the picture, its corners rounded by a mask
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
					opacity: picture.status === Image.Ready ? 1 : 0

					Behavior on opacity {
						NumberAnimation {
							duration: 200
						}
					}
				}

				// its name, on hover or when picked with the keys: plain text with a soft shadow
				Text {
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					anchors.margins: 10
					text: root.label(tile.modelData)
					elide: Text.ElideRight
					color: "white"
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.DemiBold
					opacity: hover.hovered || tile.picked && search.text ? 1 : 0
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

				// set: a ring and a tick; picked with the keys: a thin ring
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
				onClicked: {
					root.current = tile.index;
					Wallpaper.set(tile.modelData);
				}
			}
		}
	}

	Text {
		anchors.centerIn: grid
		visible: root.shown.length === 0
		width: grid.width - 40
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: Wallpaper.files.length ? "Nothing matches." : "No images in " + Wallpaper.folders.join(", ")
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	// the rotate choices, under the chip; a click elsewhere closes them
	MouseArea {
		anchors.fill: parent
		visible: menu.open
		onClicked: menu.open = false
	}

	Rectangle {
		id: menu

		property bool open: false

		x: header.x + rotate.x
		y: header.y + header.height + (open ? 6 : 0)
		width: Math.max(rotate.width, 150)
		height: choices.implicitHeight + 12
		radius: 12
		color: Theme.surface
		border.width: 1
		border.color: Qt.alpha(Theme.border, 0.8)
		opacity: open ? 1 : 0
		visible: opacity > 0

		Behavior on opacity {
			NumberAnimation {
				duration: 150
			}
		}

		Behavior on y {
			NumberAnimation {
				duration: 180
				easing.type: Easing.OutCubic
			}
		}

		Column {
			id: choices

			x: 6
			y: 6
			width: parent.width - 12

			Repeater {
				model: root.rotations

				delegate: Rectangle {
					id: choice

					required property var modelData
					readonly property bool on: Config.wallpaper.rotate === modelData.value

					width: choices.width
					height: 32
					radius: 8
					color: choiceHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

					Text {
						x: 10
						anchors.verticalCenter: parent.verticalCenter
						text: choice.modelData.label
						color: choice.on ? Theme.primary : Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: choice.on ? Font.DemiBold : Font.Normal
					}

					Glyph {
						visible: choice.on
						anchors.right: parent.right
						anchors.rightMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						glyph: Icons.g("check")
						font.pixelSize: 13
						color: Theme.primary
					}

					HoverHandler {
						id: choiceHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							Config.wallpaper.rotate = choice.modelData.value;
							Config.save();
							menu.open = false;
						}
					}
				}
			}
		}
	}
}
