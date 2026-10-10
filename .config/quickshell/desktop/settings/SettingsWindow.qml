pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.control
import qs.services
import qs.widgets

// The settings window: a sidebar of pages, each a column of settings that apply at once and are
// written to ~/.config/desktop/shell.json (in the repo). A real window, so i3 floats it (see
// look.conf) and the keyboard works. Escape or focusing another window closes it.
FloatingWindow {
	id: root

	property string page: Panel.settingsPage

	readonly property var pages: [
		{ key: "bar", glyph: Icons.g("app-window"), title: "Bar", flip: Config.position === "top" },
		{ key: "appearance", glyph: Icons.g("palette"), title: "Appearance" },
		{ key: "notifications", glyph: Icons.g("bell"), title: "Notifications" },
		{ key: "levels", glyph: Icons.g("adjustments"), title: "Levels" },
		{ key: "power", glyph: Icons.g("power"), title: "Power" },
		{ key: "timeshift", glyph: Icons.g("history"), title: "Timeshift" },
		{ key: "keys", glyph: Icons.g("keyboard"), title: "Keys" }
	]


	// another window taking the focus closes it
	Connections {
		target: WindowManager

		function onWindowEvent(data: var): void {
			const name = data.container?.name ?? "";
			// a named window other than this one, once it has settled (its own mapping fires focus too)
			if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				Panel.settingsOpen = false;
		}
	}

	ElapsedTimer {
		id: opened
	}

	title: "Desktop settings"
	implicitWidth: 920
	implicitHeight: 640
	minimumSize: Qt.size(760, 480)
	color: Theme.bg
	onVisibleChanged: if (!visible) Panel.settingsOpen = false

	Item {
		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: Panel.settingsOpen = false
	}

	// sidebar
	Rectangle {
		id: sidebar

		width: 210
		height: parent.height
		color: Qt.alpha(Theme.surface, 0.5)

		Text {
			x: 22
			y: 22
			text: "Settings"
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: Theme.px(20)
			font.weight: Font.DemiBold
		}

		Column {
			x: 12
			y: 70
			width: parent.width - 24
			spacing: 4

			Repeater {
				model: root.pages

				delegate: Rectangle {
					id: entry

					required property var modelData
					readonly property bool on: root.page === modelData.key

					width: parent.width
					height: 40
					radius: 10
					color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.07) : "transparent"

					Row {
						anchors.left: parent.left
						anchors.leftMargin: 14
						anchors.verticalCenter: parent.verticalCenter
						spacing: 12

						Glyph {
							width: 20
							rotation: entry.modelData.flip ? 180 : 0
							glyph: entry.modelData.glyph
							font.pixelSize: 16
							font.weight: Font.Normal
							color: entry.on ? Theme.primaryText : Theme.fg
							filled: entry.on
						}

						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: entry.modelData.title
							color: entry.on ? Theme.primaryText : Theme.fg
							font.family: Theme.fontSans
							font.hintingPreference: Theme.hinting
							font.pixelSize: Theme.textBody
							font.weight: Font.Medium
						}
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Panel.settingsPage = entry.modelData.key
					}
				}
			}
		}

		Text {
			x: 22
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 18
			width: parent.width - 44
			wrapMode: Text.Wrap
			text: "Saved to ~/.config/desktop/shell.json"
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: Theme.textCaption
		}
	}

	// the page's title (and the Keys page's search), fixed above what scrolls
	Column {
		id: header

		anchors.left: sidebar.right
		anchors.leftMargin: 32
		anchors.right: parent.right
		anchors.rightMargin: 32
		y: 28
		spacing: 16

		Text {
			text: root.pages.find(p => p.key === root.page)?.title ?? ""
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: Theme.px(22)
			font.weight: Font.DemiBold
		}

		TextField {
			id: keysSearch

			visible: root.page === "keys"
			width: parent.width
			placeholder: "Search keys"
		}
	}

	Flickable {
		id: content

		ScrollBoost {}

		anchors.left: sidebar.right
		anchors.right: parent.right
		anchors.top: header.bottom
		anchors.topMargin: 6
		anchors.bottom: parent.bottom
		contentHeight: pageColumn.implicitHeight + 60
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		Column {
			id: pageColumn

			x: 32
			y: 16
			width: content.width - 64
			spacing: 22

			// the page showing, made when picked (Keys stays, to keep its search)
			Loader {
				visible: item !== null // none on Keys: no gap above it
				width: parent.width
				sourceComponent: ({ bar: bar, appearance: appearance, notifications: popups, levels: levels, power: power, timeshift: timeshift })[root.page] ?? null

				Component {
					id: bar

					BarPage {}
				}

				Component {
					id: appearance

					AppearancePage {}
				}

				Component {
					id: popups

					PopupsPage {}
				}

				Component {
					id: levels

					LevelsPage {}
				}

				Component {
					id: power

					PowerPage {}
				}

				Component {
					id: timeshift

					TimeshiftPage {}
				}
			}

			// Keys: every binding, read from i3's config
			KeybindsPage {
				visible: root.page === "keys"
				width: parent.width
				query: keysSearch.text
			}
		}
	}
}
