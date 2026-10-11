pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Wallpapers, dropping out of the bar (a HangingPanel): search by name, the current theme's folder
// or all of them, a rotate chip for how often a new one comes, and shuffle.
HangingPanel {
	id: root

	readonly property var rotations: [
		{ value: "off", label: "Never" },
		{ value: "5m", label: "Every 5 min" },
		{ value: "1h", label: "Hourly" },
		{ value: "1d", label: "Daily" },
		{ value: "boot", label: "Each boot" }
	]
	property bool all: Wallpaper.themeFiles.length === 0
	readonly property var shown: {
		const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
		return (all ? Wallpaper.files : Wallpaper.themeFiles).filter(f => {
			const name = Format.fileName(f).toLowerCase();
			return words.every(w => name.includes(w));
		});
	}
	property int current: Math.max(0, shown.indexOf(Wallpaper.current))

	function label(path: string): string {
		return Format.fileName(path).replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ");
	}

	name: "wallpaper"
	open: Panel.wallpaperOpen
	panelWidth: Panel.sizes.wallpaper.width
	panelHeight: Panel.sizes.wallpaper.height
	onDismissed: Panel.wallpaperOpen = false
	onShownChanged: current = Math.max(0, Math.min(current, shown.length - 1))
	// rescan, for images deleted, added or moved since the last look
	Component.onCompleted: Wallpaper.scan()

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

				UiText {
					anchors.verticalCenter: parent.verticalCenter
					text: (root.rotations.find(r => r.value === Config.wallpaper.rotate) ?? root.rotations[0]).label
					color: rotate.on ? Theme.fg : Theme.fgMuted
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

		delegate: WallpaperTile {
			picked: root.current === index
			label: root.label(modelData)
			searching: search.text !== ""
			onChosen: {
				root.current = index;
				Wallpaper.set(modelData);
			}
		}
	}

	UiText {
		anchors.centerIn: grid
		visible: root.shown.length === 0
		width: grid.width - 40
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: Wallpaper.files.length ? "Nothing matches." : "No images in " + Wallpaper.folders.join(", ")
		color: Theme.fgMuted
	}

	MouseArea {
		anchors.fill: parent
		visible: menu.open
		onClicked: menu.open = false
	}

	RotateMenu {
		id: menu

		x: header.x + rotate.x
		y: header.y + header.height + (open ? 6 : 0)
		width: Math.max(rotate.width, 150)
		choices: root.rotations
	}
}
