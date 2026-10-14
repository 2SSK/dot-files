pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// The launcher, dropping out of the bar (a HangingPanel): one search over apps, emoji, files and
// themes, switched with Tab, Shift+Tab or the chips.
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
	panelWidth: Panel.sizes.launcher.width
	panelHeight: Panel.sizes.launcher.height
	onDismissed: Panel.launcherOpen = false
	onResultsChanged: current = Math.min(current, Math.max(0, results.length - 1))
	onModeChanged: {
		search.text = mode === "files" ? "~/" : "";
		current = 0;
		prepare();
		findLater.stop(); // the changed search queued one; prepare() has just run it
	}
	onOpened: {
		search.text = mode === "files" ? "~/" : "";
		current = 0;
		prepare();
		findLater.stop();
		search.focusField();
	}

	function prepare(): void {
		if (mode === "files")
			Launcher.findFiles(search.text);
		else if (mode === "themes")
			Launcher.loadThemes();
	}

	// the file search runs a moment after typing stops
	Timer {
		id: findLater

		interval: 60
		onTriggered: Launcher.findFiles(search.text)
	}

	TextField {
		id: search

		x: 16
		y: 16
		width: parent.width - 32
		height: 42
		placeholder: ({ apps: "Search apps", emoji: "Search emoji", files: "~/ your files · ~/. your dotfiles · /etc/, /tmp/", themes: "Search themes" })[root.mode]
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

			delegate: ResultRow {
				selected: root.current === index
				onMoved: root.current = index
				onPicked: action => root.pick(index, action)
			}
		}

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

				PointerPick {
					id: cellHover

					onMoved: root.current = cell.index
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
							duration: Theme.quick
							easing.type: Theme.curve
						}
					}
				}

				ThemeCard {
					visible: !cell.emoji
					anchors.fill: parent
					anchors.margins: 6
					colours: cell.colours
					name: cell.emoji ? "" : cell.modelData.name
					applied: cell.applied
					selected: root.current === cell.index
					hovered: cellHover.hovered
				}
			}
		}

		UiText {
			anchors.centerIn: parent
			visible: root.results.length === 0 && !(root.mode === "files" && Launcher.searching)
			text: search.text && search.text !== "~/" ? "Nothing matches." : root.mode === "files" ? "Nothing changed this week: type a name, a dot for your dotfiles, or /etc/." : "Nothing here."
			color: Theme.fgMuted
		}
	}

	UiText {
		id: footer

		x: 18
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 12
		width: parent.width - 36
		elide: Text.ElideRight
		text: root.mode === "emoji" && root.results[root.current] ? root.results[root.current].name : (root.modes.find(m => m.key === root.mode)?.hint ?? "")
		color: Theme.fgMuted
		font.pixelSize: Theme.textLabel
	}
}
