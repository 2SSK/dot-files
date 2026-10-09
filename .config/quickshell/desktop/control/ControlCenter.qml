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
						color: entry.on ? Theme.onPrimary : Theme.fg
						filled: entry.on
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

				delegate: Rectangle {
					id: action

					required property var modelData

					width: 42
					height: 42
					radius: 12
					color: actionHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

					Glyph {
						anchors.centerIn: parent
						glyph: action.modelData.glyph
						font.pixelSize: 18
						font.weight: Font.Normal
						color: Theme.fg
					}

					HoverHandler {
						id: actionHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: action.modelData.act()
					}
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
			font.family: Theme.fontSans
			font.pixelSize: 18
			font.weight: Font.DemiBold
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 8

			Repeater {
				model: [...(page.item?.actions ?? []).filter(a => a.show !== false), { glyph: Icons.g("x"), on: false, act: () => Panel.controlOpen = false }]

				delegate: Rectangle {
					id: button

					required property var modelData

					width: 38
					height: 38
					radius: 11
					color: modelData.on ? Theme.primary : buttonHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.7)
					border.width: modelData.on ? 0 : 1
					border.color: Qt.alpha(Theme.border, 0.7)

					Glyph {
						anchors.centerIn: parent
						glyph: button.modelData.glyph
						font.pixelSize: 15
						font.weight: Font.Normal
						color: button.modelData.on ? Theme.onPrimary : Theme.fg
						filled: button.modelData.on ?? false
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

	Flickable {
		anchors.left: header.left
		anchors.right: header.right
		anchors.top: header.bottom
		anchors.topMargin: 14
		anchors.bottom: parent.bottom
		contentHeight: page.implicitHeight + 16
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		Loader {
			id: page

			width: parent.width
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
