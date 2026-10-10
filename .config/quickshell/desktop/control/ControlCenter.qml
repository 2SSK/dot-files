pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The control center (a HangingPanel): an icon sidebar of pages, a header with the page's title,
// its buttons and ✕, then the page; the bar's widgets open their page (Panel.controlPage).
HangingPanel {
	id: root

	readonly property var pages: [
		{ key: "home", glyph: Icons.g("home"), component: home },
		{ key: "calendar", glyph: Icons.g("calendar"), component: calendar },
		{ key: "system", glyph: Icons.g("activity"), component: system },
		{ key: "notifications", glyph: Icons.g("bell"), component: notifications },
		{ key: "wifi", glyph: Icons.g("wifi"), component: wifi },
		{ key: "bluetooth", glyph: Icons.g("bluetooth"), component: bluetooth },
		{ key: "todo", glyph: Icons.g("checklist"), component: todo },
		{ key: "notes", glyph: Icons.g("notes"), component: notes }
	]

	name: "control center"
	open: Panel.controlOpen
	panelWidth: Panel.controlWidth
	panelHeight: Panel.controlHeight
	onDismissed: Panel.controlOpen = false
	// between pages: Ctrl+Tab (Shift: back) or Ctrl+PgDn/PgUp, Alt+1…8 straight to one; on Home,
	// the media keys: Space plays or pauses, ← → skip
	function turn(by: int): void {
		const at = pages.findIndex(p => p.key === Panel.controlPage);
		Panel.controlPage = pages[(Math.max(0, at) + by + pages.length) % pages.length].key;
	}

	onKeyPressed: event => {
		const ctrl = event.modifiers & Qt.ControlModifier;
		if (ctrl && (event.key === Qt.Key_Tab || event.key === Qt.Key_PageDown)) {
			turn(1);
			event.accepted = true;
			return;
		}
		if (ctrl && (event.key === Qt.Key_Backtab || event.key === Qt.Key_PageUp)) {
			turn(-1);
			event.accepted = true;
			return;
		}
		if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + pages.length) {
			Panel.controlPage = pages[event.key - Qt.Key_1].key;
			event.accepted = true;
			return;
		}
		const player = Media.player;
		if (Panel.controlPage !== "home" || !player)
			return;
		if (event.key === Qt.Key_Space && player.canTogglePlaying)
			player.togglePlaying();
		else if (event.key === Qt.Key_Left && player.canGoPrevious)
			player.previous();
		else if (event.key === Qt.Key_Right && player.canGoNext)
			player.next();
		else
			return;
		event.accepted = true;
	}

	Component.onCompleted: if (Panel.controlPage === "notifications") Notifications.unread = 0

	// seen: the bell's dot goes
	Connections {
		target: Panel

		function onControlPageChanged(): void {
			if (Panel.controlPage === "notifications")
				Notifications.unread = 0;
		}
	}

	// sidebar
	Rectangle {
		id: sidebar

		x: 14
		y: 14
		width: 58
		height: parent.height - 28
		radius: 16
		color: Qt.alpha(Theme.surface, 0.7)

		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			y: 10
			spacing: 6

			Repeater {
				model: root.pages

				delegate: Rectangle {
					id: entry

					required property var modelData
					readonly property bool on: Panel.controlPage === modelData.key

					width: 42
					height: 42
					radius: 12
					color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

					Glyph {
						anchors.centerIn: parent
						glyph: entry.modelData.glyph
						font.pixelSize: 18
						font.weight: Font.Normal
						color: entry.on ? Theme.primaryText : Theme.fg
						filled: true
					}

					Rectangle {
						visible: entry.modelData.key === "notifications" && Notifications.unread > 0 && !entry.on
						x: parent.width - 12
						y: 7
						width: 7
						height: 7
						radius: 4
						color: Theme.primary
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Panel.controlPage = entry.modelData.key
					}
				}
			}
		}

		// settings and the power menu, at the bottom
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 10
			spacing: 6

			Repeater {
				model: [
					{ glyph: Icons.g("settings"), act: () => { Panel.controlOpen = false; Panel.settingsOpen = true; } },
					{ glyph: Icons.g("power"), act: () => { Panel.controlOpen = false; Panel.openPower(); } }
				]

				delegate: IconButton {
					required property var modelData

					size: 42
					radius: 12
					glyph: modelData.glyph
					glyphSize: 18
					hoverAlpha: 0.08
					onClicked: modelData.act()
				}
			}
		}
	}

	// header: the page's title, its buttons, and close
	Item {
		id: header

		anchors.left: sidebar.right
		anchors.leftMargin: 18
		anchors.right: parent.right
		anchors.rightMargin: 16
		y: 14
		height: 42

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: page.item?.title ?? ""
			color: Theme.primary
			font.family: Theme.fontHeading
			font.hintingPreference: Theme.hinting
			font.pixelSize: Theme.px(18)
			font.weight: Font.DemiBold
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 8

			Repeater {
				model: [...(page.item?.actions ?? []).filter(a => a.show !== false), { glyph: Icons.g("x"), on: false, act: () => Panel.controlOpen = false }]

				delegate: IconButton {
					required property var modelData

					size: 38
					radius: 11
					glyph: modelData.glyph
					glyphSize: 15
					on: modelData.on ?? false
					bordered: true
					idle: Qt.alpha(Theme.surface, 0.7)
					onClicked: modelData.act()
				}
			}
		}
	}

	Flickable {
		id: view

		ScrollBoost {}

		anchors.left: header.left
		anchors.right: header.right
		anchors.top: header.bottom
		anchors.topMargin: 14
		anchors.bottom: parent.bottom
		contentHeight: page.height + 16
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		// a page sizes to its content, or (fill: Notes) takes the whole panel, never less than it needs
		Loader {
			id: page

			width: parent.width
			height: item?.fill ? Math.max(item.implicitHeight, view.height - 16) : (item?.implicitHeight ?? 0)
			sourceComponent: (root.pages.find(p => p.key === Panel.controlPage) ?? root.pages[0]).component
		}
	}

	Component {
		id: home

		HomePage {}
	}

	Component {
		id: calendar

		CalendarPage {}
	}

	Component {
		id: system

		SystemPage {}
	}

	Component {
		id: notifications

		NotificationsPage {}
	}

	Component {
		id: wifi

		WifiPage {}
	}

	Component {
		id: bluetooth

		BluetoothPage {}
	}

	Component {
		id: todo

		TodoPage {}
	}

	Component {
		id: notes

		NotesPage {}
	}
}
