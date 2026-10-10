pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.control
import qs.services
import qs.widgets

// The launcher, dropping out of the bar (a HangingPanel): one search over four modes, Tab and
// Shift+Tab (or the chips) switch them. Arrows move, Enter picks:
//   Apps: launches it (the ones used most come first).
//   Emoji: copies it (recent ones first; search by name or group).
//   Files: copies the file itself, to paste as an attachment in a chat or mail; Ctrl+Enter opens
//     it (text in nvim, web pages and PDFs in the browser, the rest in their app); Shift+Enter
//     copies its path, Ctrl+Shift+Enter its content; the row's buttons do the same.
//   Themes: applies it, and stays open to try another; the sun/moon switches dark and light.
HangingPanel {
	id: root

	readonly property var modes: [
		{ key: "apps", label: "Apps", glyph: "apps", hint: "Enter opens" },
		{ key: "emoji", label: "Emoji", glyph: "mood-smile", hint: "Enter copies" },
		{ key: "files", label: "Files", glyph: "file", hint: "Enter copies the file (paste to attach) · Ctrl+Enter opens · Shift+Enter the path · Ctrl+Shift+Enter the content" },
		{ key: "themes", label: "Themes", glyph: "palette", hint: "Enter applies" }
	]
	readonly property string mode: Panel.launcherMode
	readonly property int columns: mode === "emoji" ? 10 : mode === "themes" ? 3 : 1
	readonly property var results: {
		const q = search.text;
		if (mode === "apps")
			return Launcher.findApps(q);
		if (mode === "emoji")
			return Launcher.findEmoji(q);
		if (mode === "files")
			return Launcher.files;
		const words = q.toLowerCase().split(/\s+/).filter(w => w);
		return Launcher.themes.filter(t => words.every(w => t.name.toLowerCase().includes(w)));
	}
	property int current: 0
	readonly property string family: Theme.palette.meta?.family ?? ""
	readonly property string themeMode: Theme.palette.mode ?? "dark"

	function switchMode(step: int): void {
		const i = modes.findIndex(m => m.key === mode);
		Panel.launcherMode = modes[(i + step + modes.length) % modes.length].key;
	}

	function pick(index: int, action: string): void {
		const item = results[index];
		if (item === undefined)
			return;
		if (mode === "apps") {
			Launcher.launch(item);
		} else if (mode === "emoji") {
			Launcher.pickEmoji(item.char);
		} else if (mode === "files") {
			Launcher.file(action || "open", item);
		} else {
			Quickshell.execDetached(["theme", "set", item.family]);
			return;
		}
		Panel.launcherOpen = false;
	}

	function move(step: int): void {
		current = Math.max(0, Math.min(results.length - 1, current + step));
	}

	name: "launcher"
	open: Panel.launcherOpen
	panelWidth: Panel.launcherWidth
	panelHeight: Panel.launcherHeight
	onDismissed: Panel.launcherOpen = false
	onResultsChanged: current = Math.min(current, Math.max(0, results.length - 1))
	onModeChanged: {
		search.text = "";
		current = 0;
		prepare();
	}
	Component.onCompleted: prepare()

	function prepare(): void {
		if (mode === "files")
			Launcher.findFiles("");
		else if (mode === "themes")
			Launcher.loadThemes();
	}

	// the file search runs a moment after typing stops
	Timer {
		id: findLater

		interval: 120
		onTriggered: Launcher.findFiles(search.text)
	}

	TextField {
		id: search

		x: 16
		y: 16
		width: parent.width - 32
		height: 42
		placeholder: ({ apps: "Search apps", emoji: "Search emoji", files: "Search files in your home", themes: "Search themes" })[root.mode]
		Component.onCompleted: focusField()
		onTextChanged: {
			root.current = 0;
			if (root.mode === "files")
				findLater.restart();
		}
		onKeyPressed: event => {
			const k = event.key;
			if (k === Qt.Key_Tab || k === Qt.Key_Backtab)
				root.switchMode(k === Qt.Key_Backtab ? -1 : 1);
			else if (k === Qt.Key_Up || k === Qt.Key_Down)
				root.move((k === Qt.Key_Up ? -1 : 1) * root.columns);
			else if ((k === Qt.Key_Left || k === Qt.Key_Right) && root.columns > 1)
				root.move(k === Qt.Key_Left ? -1 : 1);
			else if (k === Qt.Key_Return || k === Qt.Key_Enter)
				root.pick(root.current, (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) ? "content" : event.modifiers & Qt.ControlModifier ? "open" : event.modifiers & Qt.ShiftModifier ? "path" : root.mode === "files" ? "file" : "open");
			else
				return;
			event.accepted = true;
		}
	}

	// the modes
	Row {
		id: tabs

		x: 16
		y: search.y + search.height + 10
		spacing: 6

		Repeater {
			model: root.modes

			delegate: Chip {
				required property var modelData

				glyph: Icons.g(modelData.glyph)
				label: modelData.label
				on: root.mode === modelData.key
				onClicked: {
					Panel.launcherMode = modelData.key;
					search.focusField();
				}
			}
		}
	}

	// dark or light, beside the theme chips
	Chip {
		visible: root.mode === "themes"
		anchors.right: parent.right
		anchors.rightMargin: 16
		y: tabs.y
		glyph: Icons.g(root.themeMode === "dark" ? "moon" : "sun")
		label: root.themeMode === "dark" ? "Dark" : "Light"
		onClicked: Quickshell.execDetached(["theme", "mode", "toggle"])
	}

	Item {
		id: area

		x: 10
		y: tabs.y + tabs.height + 10
		width: parent.width - 20
		height: parent.height - y - footer.height - 14
		clip: true

		// apps and files: a list
		ListView {
			id: list

			ScrollBoost {}

			anchors.fill: parent
			visible: root.mode === "apps" || root.mode === "files"
			model: visible ? root.results : []
			currentIndex: root.current
			spacing: 2
			boundsBehavior: Flickable.StopAtBounds
			highlightMoveDuration: 0
			highlightResizeDuration: 0
			highlightFollowsCurrentItem: true
			highlight: Rectangle {
				radius: 12
				color: Qt.alpha(Theme.primary, 0.16)
				border.width: 1
				border.color: Qt.alpha(Theme.primary, 0.5)
			}

			delegate: Item {
				id: row

				required property var modelData
				required property int index
				readonly property bool app: typeof modelData !== "string"
				readonly property string path: typeof modelData === "string" ? modelData : ""
				readonly property string fileName: path.slice(path.lastIndexOf("/") + 1)
				readonly property string ext: fileName.includes(".") ? fileName.slice(fileName.lastIndexOf(".") + 1).toLowerCase() : ""
				readonly property string kind: /^(png|jpe?g|webp|gif|svg)$/.test(ext) ? "photo" : ext === "pdf" ? "file-type-pdf" : /^(md|txt|org|rst|)$/.test(ext) ? "file-text" : "file-code"

				width: ListView.view.width
				height: 50

				HoverHandler {
					id: rowHover

					// the row under the pointer once it moves (not one that opened under a still pointer)
					property point from
					onHoveredChanged: from = point.position
					onPointChanged: if (hovered && Math.abs(point.position.x - from.x) + Math.abs(point.position.y - from.y) > 3) root.current = row.index
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.pick(row.index, root.mode === "files" ? "file" : "open")
				}

				IconImage {
					id: icon

					visible: row.app
					x: 12
					anchors.verticalCenter: parent.verticalCenter
					implicitSize: 30
					source: row.app ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
					asynchronous: true
				}

				Glyph {
					visible: !row.app
					x: 16
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g(row.kind)
					font.pixelSize: 20
					color: Theme.primary
				}

				Column {
					x: 54
					anchors.verticalCenter: parent.verticalCenter
					width: parent.width - x - (tools.visible ? tools.width + 16 : 12)
					spacing: 1

					Text {
						width: parent.width
						text: row.app ? row.modelData.name : row.fileName
						elide: Text.ElideRight
						color: Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textBody
						font.weight: Font.Medium
					}

					Text {
						width: parent.width
						visible: text !== ""
						text: row.app ? (row.modelData.genericName || row.modelData.comment || "") : row.path.slice(0, row.path.lastIndexOf("/")).replace(Quickshell.env("HOME"), "~")
						elide: row.app ? Text.ElideRight : Text.ElideMiddle
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.weight: Theme.textWeight
						font.pixelSize: Theme.textLabel
					}
				}

				// a file: open, copy its path, copy its content
				Row {
					id: tools

					visible: !row.app && (rowHover.hovered || root.current === row.index)
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.verticalCenter: parent.verticalCenter
					spacing: 4

					Repeater {
						model: [
							{ glyph: "external-link", action: "open" },
							{ glyph: "paperclip", action: "file" },
							{ glyph: "link", action: "path" },
							{ glyph: "copy", action: "content" }
						]

						delegate: Rectangle {
							id: tool

							required property var modelData

							width: 30
							height: 30
							radius: 9
							color: toolHover.hovered ? Qt.alpha(Theme.fg, 0.12) : "transparent"

							Glyph {
								anchors.centerIn: parent
								glyph: Icons.g(tool.modelData.glyph)
								font.pixelSize: 15
							}

							HoverHandler {
								id: toolHover
							}

							MouseArea {
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: root.pick(row.index, tool.modelData.action)
							}
						}
					}
				}
			}
		}

		// emoji and themes: a grid
		GridView {
			id: grid

			ScrollBoost {}

			anchors.fill: parent
			visible: root.mode === "emoji" || root.mode === "themes"
			model: visible ? root.results : []
			currentIndex: root.current
			cellWidth: Math.floor(width / root.columns)
			cellHeight: root.mode === "emoji" ? cellWidth : Math.round(cellWidth * 0.66)
			boundsBehavior: Flickable.StopAtBounds
			highlightFollowsCurrentItem: true
			highlightMoveDuration: 0
			highlight: Rectangle {
				radius: 14
				color: root.mode === "emoji" ? Qt.alpha(Theme.primary, 0.18) : "transparent"
				border.width: root.mode === "emoji" ? 1 : 0
				border.color: Qt.alpha(Theme.primary, 0.5)
			}

			delegate: Item {
				id: cell

				required property var modelData
				required property int index
				readonly property bool emoji: root.mode === "emoji"
				readonly property var colours: emoji ? ({}) : (modelData[root.themeMode] ?? modelData.dark)
				readonly property bool applied: !emoji && modelData.family === root.family

				width: grid.cellWidth
				height: grid.cellHeight

				HoverHandler {
					id: cellHover

					// the row under the pointer once it moves (not one that opened under a still pointer)
					property point from
					onHoveredChanged: from = point.position
					onPointChanged: if (hovered && Math.abs(point.position.x - from.x) + Math.abs(point.position.y - from.y) > 3) root.current = cell.index
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						root.current = cell.index;
						root.pick(cell.index, "open");
					}
				}

				Text {
					visible: cell.emoji
					anchors.centerIn: parent
					text: cell.emoji ? cell.modelData.char : ""
					font.family: "Noto Color Emoji"
					font.pixelSize: 28
					scale: cellHover.hovered ? 1.2 : 1

					Behavior on scale {
						NumberAnimation {
							duration: 120
							easing.type: Easing.OutBack
						}
					}
				}

				// a theme: a small window in its colours
				Rectangle {
					visible: !cell.emoji
					anchors.fill: parent
					anchors.margins: 6
					radius: 14
					color: cell.colours.bg ?? "transparent"
					border.width: cell.applied ? 3 : root.current === cell.index ? 2 : 1
					border.color: cell.applied ? Theme.primary : root.current === cell.index ? Qt.alpha(Theme.fg, 0.6) : Qt.alpha(Theme.border, 0.8)
					scale: cellHover.hovered ? 1.03 : 1

					Behavior on scale {
						NumberAnimation {
							duration: 140
							easing.type: Easing.OutCubic
						}
					}

					Rectangle {
						x: 10
						y: 10
						width: parent.width - 20
						height: 14
						radius: 7
						color: cell.colours.surface ?? "transparent"

						Row {
							anchors.verticalCenter: parent.verticalCenter
							x: 6
							spacing: 4

							Repeater {
								model: ["primary", "secondary", "accent", "success", "error"]

								delegate: Rectangle {
									required property string modelData

									width: 6
									height: 6
									radius: 3
									color: cell.colours[modelData] ?? "transparent"
								}
							}
						}
					}

					Text {
						x: 12
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 10
						text: cell.emoji ? "" : cell.modelData.name
						color: cell.colours.fg ?? Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textBody
						font.weight: Font.DemiBold
					}

					Rectangle {
						anchors.right: parent.right
						anchors.bottom: parent.bottom
						anchors.margins: 10
						width: 20
						height: 20
						radius: 10
						color: cell.colours.primary ?? "transparent"
						scale: cell.applied ? 1 : 0

						Behavior on scale {
							NumberAnimation {
								duration: 200
								easing.type: Easing.OutBack
							}
						}

						Glyph {
							anchors.centerIn: parent
							glyph: Icons.g("check")
							font.pixelSize: 12
							color: cell.colours.on_primary ?? Theme.primaryText
						}
					}
				}
			}
		}

		Text {
			anchors.centerIn: parent
			visible: root.results.length === 0 && !(root.mode === "files" && Launcher.searching)
			text: search.text ? "Nothing matches." : root.mode === "files" ? "Nothing changed this week; type to search." : "Nothing here."
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: Theme.textBody
		}
	}

	// what Enter does, or the emoji's name
	Text {
		id: footer

		x: 18
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 12
		width: parent.width - 36
		elide: Text.ElideRight
		text: root.mode === "emoji" && root.results[root.current] ? root.results[root.current].name : (root.modes.find(m => m.key === root.mode)?.hint ?? "")
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textLabel
	}
}
