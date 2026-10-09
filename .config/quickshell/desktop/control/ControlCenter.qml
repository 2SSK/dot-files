pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs
import qs.services
import qs.widgets

// The control center: an icon sidebar of pages beside the page. A real window (X11 popups can't
// take the keyboard): i3 floats it (look.conf) and the shell places it under the bar at the right
// of the focused screen. Escape, the key again, or focusing another window closes it.
FloatingWindow {
	id: root

	readonly property var pages: [
		{ key: "home", glyph: "\u{EB06}", title: "Home" },
		{ key: "calendar", glyph: "\u{EAB0}", title: "Calendar" },
		{ key: "notifications", glyph: "\u{EAA2}", title: "Notifications" }
	]
	readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]

	title: "Desktop control center"
	implicitWidth: 470
	implicitHeight: 640
	color: Theme.bg
	onVisibleChanged: if (!visible) Panel.controlOpen = false

	// i3 maps it centred; move it under the bar's end, once mapped
	Timer {
		running: true
		interval: 30
		onTriggered: {
			const top = Panel.barShown && Config.position === "top" ? Config.bar.size + (Config.island ? 6 : 0) : 0;
			const x = root.screen.x + root.screen.width - root.implicitWidth - 12;
			const y = Config.position === "bottom" ? root.screen.y + root.screen.height - root.implicitHeight - Config.bar.size - 18 : root.screen.y + top + 10;
			I3.dispatch(`[title="^Desktop control center$"] move position ${Math.round(x)} ${Math.round(y)}`);
		}
	}

	// another window taking the focus closes it, as a panel would
	I3IpcListener {
		subscriptions: ["window"]
		onIpcEvent: event => {
			const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
			if (data.change === "focus" && data.container?.name !== root.title)
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
			color: Qt.alpha(Theme.surface, 0.5)

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

	Component.onCompleted: if (Panel.controlPage === "notifications") Notifications.unread = 0
}
