pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs
import qs.services
import qs.widgets

// The control center: a panel that drops out of the middle of the bar, in its colour, square where
// it meets the bar. The window is transparent and as big as the screen, so i3 can only put it at the
// screen's corner (look.conf) and the panel is drawn under the bar inside it; a click anywhere off
// the panel lands on the window and closes it. An icon sidebar of pages, a header with the page's
// title, its buttons and ✕, then the page; the bar's widgets open their page. A real window, as X11
// popups can't take the keyboard. Escape, ✕, focusing another window or a click off it closes it.
FloatingWindow {
	id: root

	readonly property var pages: [
		{ key: "home", glyph: "\u{EB06}", component: home },
		{ key: "calendar", glyph: "\u{EAB0}", component: calendar },
		{ key: "system", glyph: "\u{EB03}", component: system },
		{ key: "notifications", glyph: "\u{EAA2}", component: notifications },
		{ key: "wifi", glyph: "\u{F05A9}", component: wifi },
		{ key: "bluetooth", glyph: "\u{F00AF}", component: bluetooth },
		{ key: "todo", glyph: "\u{EAB3}", component: todo },
		{ key: "notes", glyph: "\u{EB26}", component: notes }
	]
	readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]
	readonly property bool below: Config.position !== "bottom" // hangs below the bar, else above it
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	// centred under the bar, flush with it
	readonly property real px: Math.round(island.x + (island.width - panelWidth) / 2)
	readonly property real py: !Panel.barShown ? (below ? 0 : screen.height - panelHeight) : below ? island.y + island.height : island.y - panelHeight

	readonly property int panelWidth: 760
	readonly property int panelHeight: 640
	property bool placed: false // mapped: the panel may drop in

	title: "Desktop control center"
	implicitWidth: screen.width
	implicitHeight: screen.height
	color: "transparent"
	onVisibleChanged: if (!visible) Panel.controlOpen = false

	Component.onCompleted: {
		if (Panel.controlPage === "notifications")
			Notifications.unread = 0;
	}

	// one frame to be mapped, then the panel drops
	Timer {
		running: true
		interval: 40
		onTriggered: root.placed = true
	}

	ElapsedTimer {
		id: opened
	}

	// another window taking the focus closes it, as a panel would
	I3IpcListener {
		subscriptions: ["window"]
		onIpcEvent: event => {
			const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
			const name = data.container?.name ?? "";
			if (data.change === "focus" && name && !name.startsWith("Desktop control center") && opened.elapsed() > 600)
				Panel.controlOpen = false;
		}
	}

	// seen: the bell's dot goes
	Connections {
		target: Panel

		function onControlPageChanged(): void {
			if (Panel.controlPage === "notifications")
				Notifications.unread = 0;
		}
	}

	// a click off the panel closes it
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: Panel.controlOpen = false
	}

	// the panel's place under the bar; the panel slides out of its edge
	Item {
		x: root.px
		y: root.py
		width: root.panelWidth
		height: root.panelHeight
		clip: true

		Rectangle {
			id: card

			width: root.panelWidth
			height: root.panelHeight
			y: root.placed && Panel.controlOpen ? 0 : root.below ? -height : height
			color: Qt.alpha(Theme.bg, Math.max(Config.bar.opacity, 0.92))
			topLeftRadius: root.below ? 0 : 18
			topRightRadius: root.below ? 0 : 18
			bottomLeftRadius: root.below ? 18 : 0
			bottomRightRadius: root.below ? 18 : 0
			clip: true

			Behavior on y {
				NumberAnimation {
					duration: Panel.controlOpen ? 260 : 200
					easing.type: Panel.controlOpen ? Easing.OutCubic : Easing.InCubic
				}
			}

			Item {
				anchors.fill: parent
				focus: true
				Keys.onEscapePressed: Panel.controlOpen = false

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
									text: entry.modelData.glyph
									font.pixelSize: 18
									font.weight: Font.Normal
									color: entry.on ? Theme.onPrimary : Theme.fg
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
								{ glyph: "\u{EB51}", act: () => { Panel.controlOpen = false; Panel.settingsOpen = true; } },
								{ glyph: "\u{F0425}", act: () => { Panel.controlOpen = false; Panel.openPower(); } }
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
							model: [...(page.item?.actions ?? []).filter(a => a.show !== false), { glyph: "\u{EA76}", on: false, act: () => Panel.controlOpen = false }]

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
									text: button.modelData.glyph
									font.pixelSize: 15
									font.weight: Font.Normal
									color: button.modelData.on ? Theme.onPrimary : Theme.fg
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
