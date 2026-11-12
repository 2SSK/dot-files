pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The control center (a HangingPanel): a row of page tabs at the top (a highlight slides to the one
// open) with the page's buttons, Settings and Power beside it, then the page; the bar's widgets open
// their page (Panel.controlPage); Settings and Power only on the home page. To-do and Notes have keys
// of their own and no tab: open, they show a way back instead.
HangingPanel {
	id: root

	readonly property var pages: [
		{ key: "home", glyph: Icons.g("home"), component: home },
		{ key: "calendar", glyph: Icons.g("calendar"), component: calendar },
		{ key: "system", glyph: Icons.g("activity"), component: system },
		{ key: "notifications", glyph: Icons.g("bell"), component: notifications },
		{ key: "wifi", glyph: Icons.g("wifi"), component: wifi },
		{ key: "bluetooth", glyph: Icons.g("bluetooth"), component: bluetooth },
		{ key: "todo", glyph: Icons.g("checklist"), component: todo, tab: false },
		{ key: "notes", glyph: Icons.g("notes"), component: notes, tab: false }
	]
	readonly property var tabs: pages.filter(p => p.tab !== false)
	readonly property int tabIndex: tabs.findIndex(p => p.key === pageKey)

	readonly property string pageKey: pages.some(p => p.key === Panel.controlPage) ? Panel.controlPage : pages[0].key
	property Loader page: null // the page showing: its title and buttons go in the header

	name: "control center"
	open: Panel.controlOpen
	panelWidth: Panel.sizes.control.width
	panelHeight: Panel.sizes.control.height
	onDismissed: Panel.controlOpen = false
	function turn(by: int): void {
		const at = tabs.findIndex(p => p.key === Panel.controlPage);
		Panel.controlPage = tabs[(Math.max(0, at) + by + tabs.length) % tabs.length].key;
	}

	onKeyPressed: event => {
		const ctrl = event.modifiers & Qt.ControlModifier;
		// with Ctrl held, Shift+Tab arrives as Tab and Shift, not as Backtab
		const back = event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier));
		if (ctrl && (back || event.key === Qt.Key_PageUp)) {
			turn(-1);
			event.accepted = true;
			return;
		}
		if (ctrl && (event.key === Qt.Key_Tab || event.key === Qt.Key_PageDown)) {
			turn(1);
			event.accepted = true;
			return;
		}
		if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + tabs.length) {
			Panel.controlPage = tabs[event.key - Qt.Key_1].key;
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

	onOpened: if (Panel.controlPage === "notifications") Notifications.unread = 0

	Connections {
		target: Panel

		function onControlPageChanged(): void {
			if (Panel.controlPage === "notifications")
				Notifications.unread = 0;
		}
	}

	Item {
		id: header

		x: 14
		y: 14
		width: parent.width - 28
		height: 34

		// the tabs, a highlight sliding under the one open
		Rectangle {
			id: strip

			readonly property real cell: 36

			visible: root.tabIndex >= 0
			width: root.tabs.length * cell + 6
			height: parent.height
			radius: Theme.radiusCard
			color: Qt.alpha(Theme.surface, 0.62)

			Rectangle {
				x: 3 + Math.max(0, root.tabIndex) * strip.cell
				y: 3
				width: strip.cell
				height: parent.height - 6
				radius: Theme.radiusCard - 3
				color: Theme.bg

				Behavior on x {
					NumberAnimation {
						duration: Theme.normal
						easing.type: Theme.curve
					}
				}
			}

			Row {
				x: 3
				y: 3

				Repeater {
					model: root.tabs

					delegate: Item {
						id: tab

						required property var modelData
						readonly property bool on: root.pageKey === modelData.key

						width: strip.cell
						height: strip.height - 6

						Glyph {
							anchors.centerIn: parent
							glyph: tab.modelData.glyph
							font.pixelSize: 16
							color: tab.on || tabHover.hovered ? Theme.fg : Theme.fgMuted

							Behavior on color {
								enabled: !Theme.switching
								ColorAnimation {
									duration: Theme.quick
								}
							}
						}

						Rectangle {
							visible: tab.modelData.key === "notifications" && Notifications.unread > 0 && !tab.on
							x: parent.width - 11
							y: 4
							width: 6
							height: 6
							radius: 3
							color: Theme.primary
						}

						HoverHandler {
							id: tabHover
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: Panel.controlPage = tab.modelData.key
						}
					}
				}
			}
		}

		// a page without a tab (To-do, Notes): the way back, and its name
		Row {
			visible: root.tabIndex < 0
			anchors.verticalCenter: parent.verticalCenter
			spacing: 10

			IconButton {
				anchors.verticalCenter: parent.verticalCenter
				size: 30
				radius: Theme.radiusCard
				glyph: Icons.g("chevron-left")
				glyphSize: 16
				onClicked: Panel.controlPage = "home"
			}

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				text: root.page?.item?.title ?? ""
				font.family: Theme.fontHeading
				font.pixelSize: Theme.px(16)
				font.weight: Font.DemiBold
			}
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 4

			Repeater {
				// Settings and Power on the home page only; the other pages' own buttons in their place
				model: [...(root.page?.item?.actions ?? []).filter(a => a.show !== false),
					...(root.pageKey !== "home" ? [] : [
						{ glyph: Icons.g("settings"), act: () => { Panel.controlOpen = false; Panel.settingsOpen = true; } },
						{ glyph: Icons.g("power"), act: () => { Panel.controlOpen = false; Panel.openPower(); } }])]

				delegate: IconButton {
					required property var modelData

					size: 32
					radius: Theme.radiusCard
					glyph: modelData.glyph
					glyphSize: 16
					on: modelData.on ?? false
					hoverAlpha: 0.08
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
		anchors.topMargin: 12
		anchors.bottom: parent.bottom
		contentHeight: (root.page?.height ?? 0) + 16
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		// Each page made the first time it shows and then kept, so neither opening nor switching builds
		// one; a page's scans and polling run only while it's visible. It sizes to its content, or with
		// fill (Notes) takes the whole panel.
		Repeater {
			model: root.pages

			delegate: Loader {
				required property var modelData
				readonly property bool current: modelData.key === root.pageKey
				property bool used: current

				onCurrentChanged: if (current) {
					used = true;
					root.page = this;
				}
				Component.onCompleted: if (current) root.page = this
				width: view.width
				height: item?.fill ? Math.max(item.implicitHeight, view.height - 16) : (item?.implicitHeight ?? 0)
				active: used
				visible: current
				sourceComponent: modelData.component
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
