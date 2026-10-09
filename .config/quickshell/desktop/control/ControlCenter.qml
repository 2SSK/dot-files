pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs
import qs.services
import qs.widgets

// The control center: an icon sidebar of pages beside the page, hanging from the bar's end in the
// bar's colour (square where it meets the bar; picom rounds the far corners, see the picom template).
// A real window, as X11 popups can't take the keyboard: i3 floats it (look.conf) and the shell puts
// it in place. Escape, the key again, focusing another window or a click anywhere else closes it.
FloatingWindow {
	id: root

	readonly property var pages: [
		{ key: "home", glyph: "\u{EB06}", title: "Home" },
		{ key: "calendar", glyph: "\u{EAB0}", title: "Calendar" },
		{ key: "notifications", glyph: "\u{EAA2}", title: "Notifications" }
	]
	readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]

	readonly property bool below: Config.position !== "bottom" // hangs below the bar, else above it
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	// flush with the bar, its right edge where the island's rounded end begins
	readonly property real px: Config.island ? island.x + island.width - island.height / 2 - implicitWidth : screen.width - implicitWidth
	readonly property real py: !Panel.barShown ? (below ? 0 : screen.height - implicitHeight) : below ? island.y + island.height : island.y - implicitHeight

	title: below ? "Desktop control center" : "Desktop control center, above"
	implicitWidth: 470
	implicitHeight: 640
	color: Qt.alpha(Theme.bg, Config.bar.opacity)
	onPxChanged: Panel.controlRect = Qt.rect(px, py, implicitWidth, implicitHeight)
	onPyChanged: Panel.controlRect = Qt.rect(px, py, implicitWidth, implicitHeight)
	onVisibleChanged: if (!visible) Panel.controlOpen = false

	// i3 maps it centred; move it to the bar once mapped
	Timer {
		running: true
		interval: 30
		onTriggered: I3.dispatch(`[title="^${root.title}$"] move position ${Math.round(root.screen.x + root.px)} ${Math.round(root.screen.y + root.py)}`)
	}

	// another window taking the focus closes it, as a panel would
	I3IpcListener {
		subscriptions: ["window"]
		onIpcEvent: event => {
			const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
			if (data.change === "focus" && !data.container?.name?.startsWith("Desktop control center"))
				Panel.controlOpen = false;
		}
	}

	Item {
		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: Panel.controlOpen = false

		// sidebar
		Rectangle {
			id: sidebar

			width: 58
			height: parent.height
			color: Qt.alpha(Theme.surface, 0.35)

			Column {
				anchors.horizontalCenter: parent.horizontalCenter
				y: 14
				spacing: 6

				Repeater {
					model: root.pages

					delegate: Rectangle {
						id: entry

						required property var modelData
						readonly property bool on: Panel.controlPage === modelData.key

						width: 40
						height: 40
						radius: 12
						color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

						Glyph {
							anchors.centerIn: parent
							text: entry.modelData.glyph
							font.pixelSize: 18
							font.weight: Font.Normal
							color: entry.on ? Theme.onPrimary : Theme.fg
						}

						Rectangle {
							visible: entry.modelData.key === "notifications" && Notifications.unread > 0 && !entry.on
							x: parent.width - 12
							y: 6
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
				anchors.bottomMargin: 14
				spacing: 6

				Repeater {
					model: [
						{ glyph: "\u{EB51}", act: () => { Panel.controlOpen = false; Panel.settingsOpen = true; } },
						{ glyph: "\u{F0425}", act: () => { Panel.controlOpen = false; Panel.openPower(); } }
					]

					delegate: Rectangle {
						id: action

						required property var modelData

						width: 40
						height: 40
						radius: 12
						color: actionHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

						Glyph {
							anchors.centerIn: parent
							text: action.modelData.glyph
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

		Flickable {
			anchors.left: sidebar.right
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			contentHeight: page.implicitHeight + 40
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			Loader {
				id: page

				x: 18
				y: 20
				width: parent.width - 36
				sourceComponent: ({ home, calendar, notifications })[Panel.controlPage] ?? home
			}
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
		id: notifications

		NotificationsPage {}
	}

	// seen: the bell's dot goes
	Connections {
		target: Panel

		function onControlPageChanged(): void {
			if (Panel.controlPage === "notifications")
				Notifications.unread = 0;
		}
	}

	Component.onCompleted: {
		Panel.controlRect = Qt.rect(px, py, implicitWidth, implicitHeight);
		if (Panel.controlPage === "notifications")
			Notifications.unread = 0;
	}
}
