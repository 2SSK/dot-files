pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.control
import qs.services
import qs.widgets

// The clipboard history, dropping out of the bar (a HangingPanel). Type to search; ↑ ↓ pick,
// Enter copies and closes; a click does the same. On an item: pin it (kept across restarts), save
// it as a code note, or remove it. Pinned items come first.
HangingPanel {
	id: root

	readonly property var entries: {
		const q = search.text.toLowerCase();
		const pinned = Clipboard.pins.map(p => ({ text: p.text, time: p.time, pinned: true }));
		const recent = Clipboard.history.filter(h => !Clipboard.isPinned(h.text)).map(h => ({ text: h.text, time: h.time, pinned: false }));
		return [...pinned, ...recent].filter(e => !q || e.text.toLowerCase().includes(q));
	}
	property int current: 0

	function choose(index: int): void {
		const entry = entries[index];
		if (!entry)
			return;
		Clipboard.copy(entry.text);
		Panel.clipboardOpen = false;
	}

	function ago(time: real): string {
		const s = (Date.now() - time) / 1000;
		return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)}m` : s < 86400 ? `${Math.floor(s / 3600)}h` : `${Math.floor(s / 86400)}d`;
	}

	name: "clipboard"
	open: Panel.clipboardOpen
	panelWidth: 560
	panelHeight: 560
	onDismissed: Panel.clipboardOpen = false
	onEntriesChanged: current = Math.min(current, Math.max(0, entries.length - 1))

	Text {
		x: 20
		y: 22
		text: "Clipboard"
		color: Theme.primary
		font.family: Theme.fontSans
		font.pixelSize: 18
		font.weight: Font.DemiBold
	}

	Row {
		anchors.right: parent.right
		anchors.rightMargin: 16
		y: 14
		spacing: 8

		Repeater {
			model: [
				{ glyph: Icons.g("trash"), act: () => Clipboard.clear(), show: Clipboard.history.length > 0 },
				{ glyph: Icons.g("x"), act: () => Panel.clipboardOpen = false, show: true }
			]

			delegate: Rectangle {
				id: button

				required property var modelData

				visible: modelData.show
				width: 38
				height: 38
				radius: 11
				color: buttonHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.7)
				border.width: 1
				border.color: Qt.alpha(Theme.border, 0.7)

				Glyph {
					anchors.centerIn: parent
					glyph: button.modelData.glyph
					font.pixelSize: 15
					font.weight: Font.Normal
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

	TextField {
		id: search

		x: 16
		y: 64
		width: parent.width - 32
		placeholder: "Search the clipboard"
		Component.onCompleted: focusField()
		onAccepted: root.choose(root.current)
		Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
		Keys.onDownPressed: root.current = Math.min(root.entries.length - 1, root.current + 1)
		onTextChanged: root.current = 0
	}

	ListView {
		id: list

		ScrollBoost {}

		x: 16
		y: search.y + search.height + 12
		width: parent.width - 32
		height: parent.height - y - 16
		clip: true
		spacing: 6
		model: root.entries
		currentIndex: root.current
		boundsBehavior: Flickable.StopAtBounds
		highlightMoveDuration: 0
		highlightResizeDuration: 0

		delegate: Rectangle {
			id: entry

			required property var modelData
			required property int index
			readonly property bool on: root.current === index

			width: ListView.view.width
			height: Math.min(96, preview.implicitHeight + 34)
			radius: 12
			color: on ? Qt.alpha(Theme.primary, 0.18) : hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)
			border.width: on ? 1 : 0
			border.color: Qt.alpha(Theme.primary, 0.6)

			HoverHandler {
				id: hover

				// the row under the pointer once it moves (not one that opened under a still pointer)
				property point from
				onHoveredChanged: from = point.position
				onPointChanged: if (hovered && Math.abs(point.position.x - from.x) + Math.abs(point.position.y - from.y) > 3) root.current = entry.index
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: root.choose(entry.index)
			}

			Text {
				id: preview

				x: 14
				y: 10
				width: parent.width - tools.width - 28
				text: entry.modelData.text
				maximumLineCount: 3
				elide: Text.ElideRight
				wrapMode: Text.WrapAnywhere
				textFormat: Text.PlainText
				color: Theme.fg
				font.family: Theme.fontMono
				font.pixelSize: 12
			}

			Text {
				x: 14
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 8
				text: (entry.modelData.pinned ? "Pinned · " : "") + root.ago(entry.modelData.time)
				color: entry.modelData.pinned ? Theme.primary : Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 11
			}

			Row {
				id: tools

				anchors.right: parent.right
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				spacing: 4
				opacity: hover.hovered || entry.on || entry.modelData.pinned ? 1 : 0

				Repeater {
					model: [
						{ glyph: entry.modelData.pinned ? Icons.g("pin") : Icons.g("pin"), tip: "Pin", act: () => Clipboard.pin(entry.modelData.text), on: entry.modelData.pinned },
						{ glyph: Icons.g("notes"), tip: "Save as a note", act: () => { Notes.addSnippet(entry.modelData.text); Panel.clipboardOpen = false; Panel.controlPage = "notes"; Panel.controlOpen = true; }, on: false },
						{ glyph: Icons.g("x"), tip: "Remove", act: () => Clipboard.remove(entry.modelData.text), on: false }
					]

					delegate: Rectangle {
						id: tool

						required property var modelData

						width: 28
						height: 28
						radius: 8
						color: toolHover.hovered ? Qt.alpha(Theme.fg, 0.12) : "transparent"

						Glyph {
							anchors.centerIn: parent
							glyph: tool.modelData.glyph
							font.pixelSize: 14
							font.weight: Font.Normal
							color: tool.modelData.on ? Theme.primary : Theme.fg
							filled: tool.modelData.on
						}

						HoverHandler {
							id: toolHover
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: tool.modelData.act()
						}
					}
				}
			}
		}
	}

	Text {
		anchors.centerIn: list
		visible: root.entries.length === 0
		text: search.text ? "Nothing matches." : "Copy something: it shows up here."
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}
}
