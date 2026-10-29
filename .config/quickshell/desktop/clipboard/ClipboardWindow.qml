pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The clipboard, a HangingPanel: the history on the left, pinned first, the selected entry in full on
// the right. Enter copies it back as what it was (an image as an image, files as files) and closes.
HangingPanel {
	id: root

	readonly property var entries: {
		const q = search.text.toLowerCase();
		const pinned = Clipboard.pins.map(p => Object.assign({}, p, { pinned: true }));
		const recent = Clipboard.history.filter(h => !Clipboard.isPinned(h)).map(h => Object.assign({ pinned: false }, h));
		return [...pinned, ...recent].filter(e => !q || root.words(e).toLowerCase().includes(q));
	}
	property int current: 0
	readonly property var entry: entries[current] ?? null

	function words(e: var): string {
		return e.kind === "text" ? e.text : e.kind === "files" ? e.paths.join(" ") : "image picture screenshot";
	}

	function headline(e: var): string {
		if (e.kind === "image")
			return "Image";
		if (e.kind === "files")
			return e.paths.length === 1 ? Format.fileName(e.paths[0]) : `${Format.fileName(e.paths[0])} and ${e.paths.length - 1} more`;
		return e.text.trim().split("\n")[0];
	}

	// put the entry back and close; paste also pastes it as Ctrl+V or Ctrl+Shift+V would (desktop paste)
	function choose(paste: bool): void {
		if (!entry)
			return;
		Clipboard.copy(entry);
		Panel.clipboardOpen = false;
		if (paste)
			Quickshell.execDetached(["desktop", "paste"]);
	}

	name: "clipboard"
	open: Panel.clipboardOpen
	panelWidth: Panel.sizes.clipboard.width
	panelHeight: Panel.sizes.clipboard.height
	onDismissed: Panel.clipboardOpen = false
	onEntriesChanged: current = Math.min(current, Math.max(0, entries.length - 1))
	onOpened: {
		search.text = "";
		current = 0;
		search.focusField();
	}


	Item {
		id: left

		x: 16
		y: 16
		width: 360
		height: parent.height - 32

		TextField {
			id: search

			width: parent.width
			placeholder: "Search the clipboard"
			onAccepted: root.choose(true)
			// Shift+Enter only copies; Ctrl+N / Ctrl+P move down / up, as in a shell or fzf
			onKeyPressed: event => {
				if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
					root.choose(false);
					event.accepted = true;
				} else if ((event.key === Qt.Key_N || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) {
					root.current = event.key === Qt.Key_N ? Math.min(root.entries.length - 1, root.current + 1) : Math.max(0, root.current - 1);
					event.accepted = true;
				}
			}
			onTextChanged: root.current = 0
			Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
			Keys.onDownPressed: root.current = Math.min(root.entries.length - 1, root.current + 1)
		}

		ListView {
			id: list

			y: search.height + 12
			width: parent.width
			height: parent.height - y
			clip: true
			spacing: 4
			model: root.entries
			currentIndex: root.current
			boundsBehavior: Flickable.StopAtBounds
			highlightMoveDuration: 0
			highlightResizeDuration: 0

			ScrollBoost {}

			delegate: ClipboardRow {
				selected: root.current === index
				headline: root.headline(modelData)
				onMoved: root.current = index
				onPicked: root.current = index
				onActivated: root.choose(true)
			}
		}

		UiText {
			anchors.centerIn: list
			visible: root.entries.length === 0
			width: list.width - 40
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			text: search.text ? "Nothing matches." : "Copy something (text, an image, a file): it shows up here."
			color: Theme.fgMuted
		}
	}


	ClipboardPreview {
		id: preview

		anchors.left: left.right
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 16
		y: 16
		height: parent.height - 32
		entry: root.entry
		onCopied: root.choose(false)
	}

	// clear the history; pins stay
	Chip {
		anchors.right: preview.right
		anchors.rightMargin: 12
		y: preview.y + 8
		visible: Clipboard.history.length > 0
		glyph: Icons.g("trash")
		label: "Clear"
		onClicked: Clipboard.clear()
	}
}
